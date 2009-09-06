# Base exporter
class Tracksperanto::Export::Base
  attr_reader :io
  
  def self.inherited(by)
    Tracksperanto.exporters << by
    super
  end
  
  # Should return the suffix and extension of this export file (like "_flame.stabilizer"). It's a class
  # method because it gets requested before the exporter is instantiated
  def self.desc_and_extension
    "data.txt"
  end
  
  def initialize(write_to_io)
    @io = write_to_io
  end
  
  # Called on export start
  def start_export( img_width, img_height)
  end
  
  # Called on export end
  def end_export
  end
  
  # Called on tracker start, one for each tracker
  def start_tracker_segment(tracker_name)
  end
  
  # Called on tracker end
  def end_tracker_segment
  end
  
  # Called for each tracker keyframe
  def export_point(at_frame_i, abs_float_x, abs_float_y, float_residual)
  end
end