require File.dirname(__FILE__) + '/helper'
require 'stringio'

class ShakeTextExportTest < Test::Unit::TestCase
  def setup
    t1 = Tracksperanto::Tracker.new {|t| t.name = "Tracker_One" }
    
    t1.keyframes << Tracksperanto::Keyframe.new do |f| 
      f.frame = 12
      f.abs_x = 123
      f.abs_y = 456
      f.residual = 0
    end
    
    t1.keyframes << Tracksperanto::Keyframe.new do |f| 
      f.frame = 14
      f.abs_x = 125
      f.abs_y = 465
      f.residual = 0.4
    end
    
    t2 = Tracksperanto::Tracker.new {|t| t.name = "Tracker_Two" }
    
    t2.keyframes << Tracksperanto::Keyframe.new do |f| 
      f.frame = 0
      f.abs_x = 406
      f.abs_y = 268
      f.residual = 0
    end
    
    t2.keyframes << Tracksperanto::Keyframe.new do |f| 
      f.frame = 1
      f.abs_x = 402.45689987
      f.abs_y = 245.89682
      f.residual = 0.4
    end
    
    @trackers = [t1, t2]
  end
  
  def test_export
    out_to = "/tmp/shakeTr_txt.txt"
    STDERR.puts "Outputting #{out_to} Shake sample text file, please verify"
    io = File.open(out_to, "w")
    
    x = Tracksperanto::Export::ShakeText.new(io)
    
    x.start_export(720, 576)
    @trackers.each do | t |
      x.start_tracker_segment(t.name)
      t.keyframes.each do | kf |
        x.export_point(kf.frame, kf.abs_x, kf.abs_y, kf.residual)
      end
    end
    x.end_export
    io.close
  end
end