
class Tracksperanto::Import::FlameStabilizer < Tracksperanto::Import::Base
  
  # Flame setups contain clear size indications
  def self.autodetects_size?
    true
  end
  
  def self.distinct_file_ext
    ".stabilizer"
  end
  
  def self.human_name
    "Flame .stabilizer file"
  end
  
  class Key
    attr_accessor :at, :value, :extrap, :interp, :left_tangent, :right_tangent
  end
  
  class ChannelBlock < Array
    include ::Tracksperanto::Casts
    cast_to_string :name
    cast_to_float :base_value
    
    def <=>(o)
      @name <=> o.name
    end
    
    def initialize(io, channel_name)
      @name = channel_name.strip
      
      base_value_matcher = /Value ([\-\d\.]+)/
      keyframe_count_matcher = /Size (\d+)/
      indent = nil
      
      while line = io.gets
        
        unless indent 
          indent = line.scan(/^(\s+)/)[1]
          end_mark = "#{indent}End"
        end
        
        if line =~ keyframe_count_matcher
          $1.to_i.times { push(extract_key_from(io)) }
        elsif line =~ base_value_matcher && empty?
          self.base_value = $1
        elsif line.strip == end_mark
          break
        end
      end
      raise "Parsed a channel #{@name} with no keyframes" if (empty? && !base_value)
    end
    
    def extract_key_from(io)
      frame = nil
      frame_matcher = /Frame ([\-\d\.]+)/
      value_matcher = /Value ([\-\d\.]+)/
      
      until io.eof?
        line = io.gets
        if line =~ frame_matcher
          frame = $1.to_i
        elsif line =~ value_matcher
          return [frame, $1.to_f]
        end
      end
      
      raise "Did not detect any keyframes!"
    end
    
    # Hack - prevents the channel to be flattened into keyframes
    # when it gets Array#flatten'ed
    def to_ary; end  
    private :to_ary
  end
  
  def each
    report_progress("Extracting setup size")
    self.width, self.height = extract_width_and_height_from_stream(@io)
    report_progress("Extracting all animation channels")
    channels = extract_channels_from_stream(@io)
    
    raise "The setup contained no channels that we could process" if channels.empty?
    raise "A channel was nil" if channels.find{|e| e.nil? }
    
    report_progress("Assembling tracker curves from channels")
    scavenge_trackers_from_channels(channels) {|t| yield(t) }
  end
  
  private
    def extract_width_and_height_from_stream(io)
      w, h = nil, nil
      
      w_matcher = /FrameWidth (\d+)/
      h_matcher = /FrameHeight (\d+)/
      
      until io.eof?
        line = io.gets
        if line =~ w_matcher
          w = $1
        elsif line =~ h_matcher
          h = $1
        end
        
        return [w, h] if (w && h)
      end
      
    end
=begin
Here's how a Flame channel looks like
The Size will not be present if there are no keyframes
  
Channel tracker1/ref/x
	Extrapolation constant
	Value 770.41
	Size 4
	KeyVersion 1
	Key 0
		Frame 1
		Value 770.41
		Interpolation constant
		End
	Key 1
		Frame 44
		Value 858.177
		Interpolation constant
		RightSlope 2.31503
		LeftSlope 2.31503
		End
	Key 2
		Frame 74
		Value 939.407
		Interpolation constant
		RightSlope 2.24201
		LeftSlope 2.24201
		End
	Key 3
		Frame 115
		Value 1017.36
		Interpolation constant
		End
	Colour 50 50 50 
	End
=end

    def extract_channels_from_stream(io)
      channels = []
      channel_matcher = /Channel (.+)\n/
      until io.eof?
        line = io.gets
        if line =~ channel_matcher && channel_is_useful?(line)
          report_progress("Extracting channel #{$1}")
          channels << ChannelBlock.new(io, $1)
        end
      end
      channels
    end
    
    USEFUL_CHANNELS = %w( /shift/x /shift/y /ref/x /ref/y ).map(&Regexp.method(:new))
    
    # This method tells the importer whether a channel that has been found in the source
    # setup is needed. If that method returns ++false++ the channel will be discarded and not
    # kept in memory. Should you need to write a module that scavenges other Flame animation channels
    # inherit from this class and rewrite this method to either return +true+ always (then all the channels
    # will be recovered) or to return +true+ only for channels that you actually need.
    def channel_is_useful?(channel_name)
      USEFUL_CHANNELS.any?{|e| channel_name =~ e }
    end
    
    REF_CHANNEL = "ref" # or "track" - sometimes works sometimes don't
    
    def scavenge_trackers_from_channels(channels)
      channels.select{|e| e.name =~ /\/#{REF_CHANNEL}\/x/}.each do | track_x |
        report_progress("Detected reference channel #{track_x}")
        yield grab_tracker(channels, track_x)
      end
    end
    
    def grab_tracker(channels, track_x)
      t = Tracksperanto::Tracker.new(:name => track_x.name.split('/').shift)
      
      report_progress("Extracting tracker #{t.name}")
      
      track_y = channels.find{|e| e.name == "#{t.name}/#{REF_CHANNEL}/y" }
      shift_x = channels.find{|e| e.name == "#{t.name}/shift/x" }
      shift_y = channels.find{|e| e.name == "#{t.name}/shift/y" }
      
      shift_tuples = zip_curve_tuples(shift_x, shift_y)
      track_tuples = zip_curve_tuples(track_x, track_y)
      
      report_progress("Detecting base value")
      base_x, base_y =  find_base_x_and_y(track_tuples, shift_tuples)
      
      total_kf = 1
      t.keyframes = shift_tuples.map do | (at, x, y) |
        # Flame keyframes are sort of minus-one based, so to start at frame 0
        # we need to decrement one frame, always. Also, the shift value is inverted!
        kf_x, kf_y = base_x - x.to_f, base_y - y.to_f
        
        report_progress("Extracting keyframe #{total_kf += 1} of #{t.name}")
        Tracksperanto::Keyframe.new(:frame => (at - 1), :abs_x => kf_x, :abs_y => kf_y)
      end
      
      return t
    end
    
    def find_base_x_and_y(track_tuples, shift_tuples)
      base_track_tuple = track_tuples.find do | track_tuple |
        shift_tuples.find { |shift_tuple| shift_tuple[0] == track_tuple [0] }
      end || track_tuples[0]
      base_track_tuple[1..2]
    end
end