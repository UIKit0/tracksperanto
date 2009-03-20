# Base exporter
class Tracksperanto::Export::Base
  
  def self.inherited(by)
    Tracksperanto.exporters << by
    super
  end
  
  def initialize(write_to_io)
    @io = write_to_io
  end
  
  # Called on export start
  def start_export(export_name, img_width, img_height)
  end
  
  # Called on export end
  def end_export
  end
  
  # Called on tracker start, one for each tracker. Start of the next tracker
  # signifies that the previous tracker has passed by
  def start_tracker_segment(tracker_name)
  end
  
  # Called for each tracker keyframe
  def export_point(at_frame_i, abs_float_x, abs_float_y, float_residual)
  end
end