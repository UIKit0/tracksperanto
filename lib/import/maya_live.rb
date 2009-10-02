class Tracksperanto::Import::MayaLive < Tracksperanto::Import::Base
  def self.human_name
    "Maya Live track export file"
  end
  
  def self.autodetects_size?
    true
  end
  
  COMMENT = /^# /
  
  def parse(original_io)
    io = Tracksperanto::ExtIO.new(original_io)
    extract_width_height_and_aspect(io.gets_non_empty)
    trackers = []
    
    while line = io.gets_and_strip
      if line =~ COMMENT
        trackers << Tracksperanto::Tracker.new(:name => line.gsub(/#{COMMENT} Name(\s+)/, ''))
        next
      end
      
      tracker_num, frame, x, y, residual = line.split
      
      abs_x, abs_y = aspect_values_to_pixels(x, y)
      trackers[-1].keyframe! :frame => frame, :abs_x => abs_x, :abs_y => abs_y,  :residual => set_residual(residual)
    end
    
    trackers
  end
  
  private
  
    def aspect_values_to_pixels(x, y)
      [
        (@width.to_f / 2.0) + (x.to_f * @x_unit.to_f),
        (@height.to_f / 2.0) + (y.to_f * @y_unit.to_f)
      ]
    end
    
    def extract_width_height_and_aspect(from_str)
      self.width, self.height = from_str.scan(/\d+/)
      @aspect = width.to_f / height.to_f
      @x_unit = width / (@aspect * 2)
      @y_unit = height / (1 * 2)
    end
    
    def set_residual(residual)
      (residual == "-1" ? 0 : residual)
    end
end