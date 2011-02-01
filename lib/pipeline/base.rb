# The base pipeline is the whole process of track conversion from start to finish. The pipeline object organizes the import formats, scans them,
# applies the default middlewares and yields them for processing. Here's how a calling sequence for a pipeline looks like:
#
#   pipe = Tracksperanto::Pipeline::Base.new
#   pipe.progress_block = lambda{|percent, msg| puts("#{msg}..#{percent.to_i}%") }
#   
#   pipe.run("/tmp/shakescript.shk", :width => 720, :height => 576) do | *all_middlewares |
#     # configure middlewares here
#   end
#
# The pipeline will also automatically allocate output files with the right extensions
# at the same place where the original file resides,
# and setup outputs for all supported export formats.
class Tracksperanto::Pipeline::Base
  EXTENSION = /\.([^\.]+)$/ #:nodoc:
  PERMITTED_OPTIONS = [:importer, :width, :height]
  
  include Tracksperanto::BlockInit
  
  # How many points have been converted. In general, the pipeline does not preserve the parsed tracker objects
  # after they have been exported
  attr_reader :converted_points
  
  # How many keyframes have been converted
  attr_reader :converted_keyframes
  
  # A block acepting percent and message vars can be assigned here.
  # When it's assigned, the pipeline will pass the status reports
  # of all the importers and exporters to the block, together with
  # percent complete
  attr_accessor :progress_block
  
  # Assign an array of exporters to use them instead of the standard ones 
  attr_accessor :exporters
  
  # Contains arrays of the form ["MiddewareName", {:param => value}]
  attr_accessor :middleware_tuples
  
  def wrap_output_with_middlewares(output)
    return output unless (middleware_tuples && middleware_tuples.any?)
    
    middleware_tuples.reverse.inject(output) do | wrapped, (middleware_name, options) |
      Tracksperanto.get_middleware(middleware_name).new(wrapped, options || {})
    end
  end
  
  # Runs the whole pipeline. Accepts the following options
  # * width - The comp width, for the case that the format does not support auto size
  # * height - The comp height, for the case that the format does not support auto size
  # * parser - The parser class, for the case that it can't be autodetected from the file name
  def run(from_input_file_path, passed_options = {}) #:yields: *all_middlewares
    
    # Reset stats
    @converted_keyframes, @converted_points = 0, 0
    
    # Assign the parser
    importer = initialize_importer_with_path_and_options(from_input_file_path, passed_options)
    
    # Check for empty files
    raise "This is an empty source file" if File.stat(from_input_file_path).size.zero?
    
    # Open the file
    read_data = File.open(from_input_file_path, "rb")
        
    # Setup a multiplexer
    mux = setup_outputs_for(from_input_file_path)
    
    # Setup middlewares
    endpoint = wrap_output_with_middlewares(mux)
    @converted_points, @converted_keyframes = run_export(read_data, importer, endpoint)
  end
  
  def report_progress(percent_complete, message)
    int_pct = percent_complete.to_f.floor # Prevent float overflow above 100 percent
    @progress_block.call(int_pct, message) if @progress_block
  end
  
  def initialize_importer_with_path_and_options(from_input_file_path, options)
    
    d = Tracksperanto::FormatDetector.new(from_input_file_path)
    
    if options[:importer]
      imp = Tracksperanto.get_importer(options[:importer])
      require_dimensions_in!(options) unless imp.autodetects_size?
      imp.new(:width => options[:width], :height => options[:height])
    elsif d.match? && d.auto_size?
      d.importer_klass.new
    elsif d.match?
      require_dimensions_in!(options)
      d.importer_klass.new(:width => options[:width], :height => options[:height])
    else
      raise "Unknown input format"
    end
  end
  
  def require_dimensions_in!(opts)
    raise "Width and height must be provided for this importer" unless (opts[:width] && opts[:height])
  end
  
  # Runs the export and returns the number of points and keyframes processed.
  # If a block is passed, the block will receive the percent complete and the last
  # status message that you can pass back to the UI
  def run_export(tracker_data_io, importer, exporter)
    points, keyframes, percent_complete = 0, 0, 0.0
    
    report_progress(percent_complete, "Starting the parser")
    
    # Report progress from the parser
    importer.progress_block = lambda { | m | report_progress(percent_complete, m) }
    
    # Wrap the input in a progressive IO, setup a lambda that will spy on the reader and 
    # update the percentage. We will only broadcast messages that come from the parser 
    # though (complementing it with a percentage)
    io_with_progress = Tracksperanto::ProgressiveIO.new(tracker_data_io) do | offset, of_total |
      percent_complete = (50.0 / of_total) * offset
    end
    @ios << io_with_progress
    
    accumulator = Tracksperanto::Accumulator.new
    importer.receiver = accumulator
    @ios << accumulator # Ensure the accumulator gets closed and tempfile unlinked
    
    importer.stream_parse(io_with_progress)
    
    report_progress(percent_complete = 50.0, "Validating #{accumulator.length} imported trackers")
    if accumulator.num_objects.zero?
      raise "Could not recover any non-empty trackers from this file. Wrong import format maybe?"
    end
    
    report_progress(percent_complete, "Starting export")
    
    percent_per_tracker = (100.0 - percent_complete) / accumulator.num_objects
    
    # Use the width and height provided by the parser itself
    exporter.start_export(importer.width, importer.height)
    accumulator.each_object_with_index do | t, tracker_idx |
      raise "Not a Tracker" unless t.is_a?(Tracksperanto::Tracker)
      
      kf_weight = percent_per_tracker / t.keyframes.length
      points += 1
      exporter.start_tracker_segment(t.name)
      t.each_with_index do | kf, idx |
        keyframes += 1
        exporter.export_point(kf.frame, kf.abs_x, kf.abs_y, kf.residual)
        report_progress(
            percent_complete += kf_weight,
            "Writing keyframe #{idx+1} of #{t.name.inspect}, #{accumulator.num_objects - tracker_idx} trackers to go"
        )
      end
      exporter.end_tracker_segment
    end
    exporter.end_export
    
    report_progress(100.0, "Wrote #{points} points and #{keyframes} keyframes")
    
    [points, keyframes]
  ensure
    @ios.map!{|e| e.close! rescue e.close }
    @ios = []
  end
  
  # Setup output files and return a single output
  # that replays to all of them
  def setup_outputs_for(input_file_path)
    file_name = File.basename(input_file_path).gsub(EXTENSION, '')
    outputs = (exporters || Tracksperanto.exporters).map do | exporter_class |
      export_name = [file_name, exporter_class.desc_and_extension].join("_")
      export_path = File.join(File.dirname(input_file_path), export_name)
      exporter_class.new(open_owned_export_file(export_path))
    end
    
    Tracksperanto::Export::Mux.new(outputs)
  end
  
  # Open the file for writing and register it to be closed automatically
  def open_owned_export_file(path_to_file)
    @ios ||= []
    @ios.push(File.open(path_to_file, "wb"))[-1]
  end
end