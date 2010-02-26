class Tracksperanto::Import::MatchMover < Tracksperanto::Import::Base
  
  def self.autodetects_size?
    true
  end
  
  def self.human_name
    "MatchMover .rz2 file"
  end
  
  def self.distinct_file_ext
    ".rz2"
  end
  
  def parse(io)
    trackers = []
    detect_format(io)
    extract_trackers(io)
  end
  
  private
  
  def detect_format(io)
    report_progress("Detecting width and height")
    lines = (0..2).map{ io.gets }
    last_line = lines[-1]
    w, h, _ = last_line.scan(/(\d+)/).flatten
    @width, @height = w.to_i, h.to_i
  end
  
  def extract_trackers(io)
    tracks = []
    while(line = io.gets) do
      tracks << extract_track(line, io) if line =~ /^pointTrack/
    end
    tracks
  end
  
  def extract_track(start_line, io)
    tracker_name = start_line.scan(/\"([^\"]+)\"/).flatten[0]
    report_progress("Extracting tracker #{tracker_name}")
    t = Tracksperanto::Tracker.new(:name => tracker_name)
    while(line = io.gets) do
      return t if line =~ /\}/
      t.keyframes.push(extract_key(line.strip)) if line =~ /^(\s+?)(\d)/
      report_progress("Extracting keyframe")
    end
    raise "Track didn't close"
  end
  
  LINE_PATTERN = /(\d+)(\s+)([\-\d\.]+)(\s+)([\-\d\.]+)(\s+)(.+)/
  
  def extract_key(line)
    frame, x, y, residual, rest = line.scan(LINE_PATTERN).flatten.reject{|e| e.strip.empty? }
    Tracksperanto::Keyframe.new(
      :frame => (frame.to_i() - 1),
      :abs_x => x,
      :abs_y => @height - y.to_f, # Top-left in MM
      :residual => extract_residual(residual)
    )
  end
  
  def extract_residual(residual_segment)
    # Parse to the first opening brace and pick the residual from there
    float_pat = /([\-\d\.]+)/
    1 - residual_segment.scan(float_pat).flatten.shift.to_f
  end
end