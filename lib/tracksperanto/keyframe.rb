# Internal representation of a keyframe, that carries info on the frame location in the clip, x y and residual.
#
# Franme numbers are zero-based (frame 0 is first frame of the clip).
# X-coordinate (abs_x) is absolute pixels from lower left corner of the comp to the right
# Y-coordinate (abs_y) is absolute pixels from lower left corner of the comp up
# Residual is how far in pixels the tracker strolls away, and is the inverse of
# correlation (with total correlation of one the residual excursion becomes zero).
class Tracksperanto::Keyframe
  include Tracksperanto::Casts
  include Tracksperanto::BlockInit
  
  # Will be raised when trying to create a keyframe without one of the
  # mandatory parameters (abs_x, abs_y or frame)
  class IncompleteError < RuntimeError
  end
  
  # Absolute integer frame where this keyframe is placed, 0 based
  attr_accessor :frame
  
  # Absolute float X value of the point, zero is lower left
  attr_accessor :abs_x
  
  # Absolute float Y value of the point, zero is lower left
  attr_accessor :abs_y
  
  # Absolute float residual (0 is "spot on")
  attr_accessor :residual
  
  cast_to_float :abs_x, :abs_y, :residual
  cast_to_int :frame
  
  def inspect
    [frame, abs_x, abs_y].inspect
  end
end