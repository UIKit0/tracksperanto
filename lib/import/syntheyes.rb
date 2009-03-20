class Tracksperanto::Import::Syntheyes < Tracksperanto::Import::Base
  def parse(file_content)
    trackers = []
    file_content.split("\n").each do | line |
      name, frame, x, y, corr = line.split
      
      # Do we already have this tracker?
      t = trackers.find {|e| e.name == name}
      if !t
        t = Tracksperanto::Tracker.new{|t| t.name = name }
        trackers << t
      end
      
      # Add the keyframe
      t.keyframes << Tracksperanto::Keyframe.new do |e| 
        e.frame = frame
        e.abs_x = convert_from_uv(width, x)
        e.abs_y = height - convert_from_uv(height, y) # Convert TL to BL
        e.residual = corr
      end
    end
    
    trackers
  end
  
  private
    def convert_from_uv(absolute_side, uv_value)
      # First, start from zero (-.1 becomes .4)
      value_off_corner = (uv_value.to_f / 2) + 0.5
      absolute_side * value_off_corner
    end
end