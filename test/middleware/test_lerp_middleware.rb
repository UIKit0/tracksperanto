require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class LerpMiddlewareTest < Test::Unit::TestCase
  def test_lerp
    receiver = flexmock
    m = Tracksperanto::Middleware::Lerp.new(receiver, :enabled => true)
    receiver.should_receive(:start_export).with(720, 576).once
    receiver.should_receive(:start_tracker_segment).with("Foo").once
    receiver.should_receive(:export_point).with(1, 1.0, 2.0, 0).once
    receiver.should_receive(:export_point).with(2, 2.0, 3.0, 0).once
    receiver.should_receive(:export_point).with(3, 3.0, 4.0, 0).once
    receiver.should_receive(:export_point).with(4, 4.0, 5.0, 0).once
    receiver.should_receive(:end_tracker_segment).once
    receiver.should_receive(:end_export).once
    
    m.start_export(720, 576)
    m.start_tracker_segment("Foo")
    m.export_point(1, 1.0, 2.0, 0)
    m.export_point(4, 4.0, 5.0, 0)
    m.end_tracker_segment
    m.end_export
  end
  
  def test_lerp_should_react_to_enabled_flag
    receiver = flexmock
    m = Tracksperanto::Middleware::Lerp.new(receiver, :enabled => false)
    receiver.should_receive(:start_export).with(720, 576).once
    receiver.should_receive(:start_tracker_segment).with("Foo").once
    receiver.should_receive(:export_point).with(1, 1.0, 2.0, 0).once
    receiver.should_receive(:export_point).with(4, 4.0, 5.0, 0).once
    receiver.should_receive(:end_tracker_segment).once
    receiver.should_receive(:end_export).once
    
    m.start_export(720, 576)
    m.start_tracker_segment("Foo")
    m.export_point(1, 1.0, 2.0, 0)
    m.export_point(4, 4.0, 5.0, 0)
    m.end_tracker_segment
    m.end_export
  end
  
end