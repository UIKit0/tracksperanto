require File.expand_path(File.dirname(__FILE__)) + '/../helper'

class LintMiddlewareTest < Test::Unit::TestCase
  def test_empty_export_raises
    m = flexmock
    m.should_receive(:start_export).once
    
    ex = Tracksperanto::Middleware::Lint.new(m)
    ex.start_export(100, 100)
    assert_raise(Tracksperanto::Middleware::Lint::NoTrackersExportedError) do
      ex.end_export
    end
    
  end
  
  def test_exporting_empty_tracker_raises
    m = flexmock
    m.should_receive(:start_export).once
    m.should_receive(:start_tracker_segment).once
    
    ex = Tracksperanto::Middleware::Lint.new(m)
    ex.start_export(100, 100)
    ex.start_tracker_segment("Foo")
    
    assert_raise(Tracksperanto::Middleware::Lint::EmptyTrackerSentError) do
      ex.end_tracker_segment
    end
  end
  

  def test_exporting_with_two_starts_raises
    m = flexmock
    m.should_receive(:start_export).once
    m.should_receive(:start_tracker_segment).once
    
    ex = Tracksperanto::Middleware::Lint.new(m)
    ex.start_export(100, 100)
    ex.start_tracker_segment("Foo")
    
    assert_raise(Tracksperanto::Middleware::Lint::TrackerRestartedError) do
      ex.start_tracker_segment("Bar")
    end
  end
  
end