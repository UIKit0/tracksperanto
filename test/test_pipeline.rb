require File.expand_path(File.dirname(__FILE__)) + '/helper'

class PipelineTest < Test::Unit::TestCase
  
  def setup
    @old_dir = Dir.pwd
    Dir.chdir(File.dirname(__FILE__))
    super
  end
  
  def create_stabilizer_file
    @stabilizer = "./input.stabilizer"
    trackers = %w( Foo Bar Baz).map do | name |
      t = Tracksperanto::Tracker.new(:name => name)
      t.keyframe!(:frame => 3, :abs_x => 100, :abs_y => 200)
      t.keyframe!(:frame => 4, :abs_x => 200, :abs_y => 120)
      t.keyframe!(:frame => 5, :abs_x => 210, :abs_y => 145)
      t
    end
    
    File.open(@stabilizer, "wb") do | f |
      exporter = Tracksperanto::Export::FlameStabilizer.new(f)
      exporter.just_export(trackers, 720, 576)
    end
  end
  
  def teardown
     Dir.glob("./input*.*").each(&File.method(:unlink))
     Dir.chdir(@old_dir)
     super
  end
  
  def test_supports_block_init
    pipeline = Tracksperanto::Pipeline::Base.new(:middleware_tuples => [:a, :b])
    assert_equal [:a, :b], pipeline.middleware_tuples
  end
  
  def test_run_with_autodetected_importer_and_size
    create_stabilizer_file
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_nothing_raised { pipeline.run(@stabilizer) }
    assert_equal 3, pipeline.converted_points
    assert_equal 9, pipeline.converted_keyframes, "Should report conversion of 9 keyframes"
  end
  
  def test_run_crashes_with_empty_file
    empty_file_path = "./input_empty.stabilizer"
    f = File.open(empty_file_path, "w"){|f| f.write('') }
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_raise(Tracksperanto::Pipeline::EmptySourceFileError) { pipeline.run(empty_file_path) }
  end
  
  def test_middleware_initialization_from_tuples
    create_stabilizer_file
    
    pipeline = Tracksperanto::Pipeline::Base.new
    pipeline.middleware_tuples = [
      ["Bla", {:foo=> 234}]
    ]
    
    mock_mux = flexmock("MUX")
    flexmock(Tracksperanto::Export::Mux).should_receive(:new).and_return(mock_mux)
    m = flexmock("middleware object")
    mock_middleware_class = flexmock("middleware class")
    
    flexmock(Tracksperanto).should_receive(:get_middleware).with("Bla").once.and_return(mock_middleware_class)
    mock_middleware_class.should_receive(:new).with(mock_mux, {:foo => 234}).once
    
    assert_raise(NoMethodError) { pipeline.run(@stabilizer) }
  end
  
  def test_run_with_autodetected_importer_that_requires_size
    FileUtils.cp("./import/samples/shake_script/four_tracks_in_one_stabilizer.shk", "./input.shk")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_raise(Tracksperanto::Pipeline::DimensionsRequiredError) { pipeline.run("./input.shk") }
  end
  
  def test_run_with_autodetected_importer_that_requires_size_when_size_supplied
    FileUtils.cp("./import/samples/shake_script/four_tracks_in_one_stabilizer.shk", "./input.shk")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_nothing_raised { pipeline.run("./input.shk", :width => 720, :height => 576) }
  end
  
  def test_run_with_overridden_importer_and_no_size
    FileUtils.cp("./import/samples/shake_script/four_tracks_in_one_stabilizer.shk", "./input.shk")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_nothing_raised { pipeline.run("./input.shk", :importer => "Syntheyes", :width => 720, :height => 576) }
    assert_equal 13, Dir.glob("./input*").length, "Twelve files should be present for the input and outputs"
  end
  
  def test_run_with_overridden_importer_and_size_for_file_that_would_be_recognized_differently
    FileUtils.cp("./import/samples/shake_script/four_tracks_in_one_stabilizer.shk", "./input.stabilizer")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_nothing_raised { pipeline.run("./input.stabilizer", :importer => "ShakeScript", :width => 720, :height => 576) }
  end
  
  def test_run_with_unknown_format_raises
    FileUtils.touch("./input.txt")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_raise(Tracksperanto::Pipeline::UnknownFormatError) { pipeline.run("./input.txt") }
    assert_raise(Tracksperanto::Pipeline::UnknownFormatError) { pipeline.run("./input.txt", :width => 100, :height => 100) }
    assert_raise(Tracksperanto::Pipeline::DimensionsRequiredError) { pipeline.run("./input.txt", :importer => "Syntheyes") }
  end
  
  def test_run_with_overridden_importer_and_size
    FileUtils.cp("./import/samples/3de_v4/3de_export_cube.txt", "./input.txt")
    pipeline = Tracksperanto::Pipeline::Base.new
    assert_raise(Tracksperanto::Pipeline::DimensionsRequiredError) { pipeline.run("./input.txt", :importer => "Equalizer4") }
    assert_nothing_raised { pipeline.run("./input.txt", :importer => "Equalizer4", :width => 720, :height => 576) }
  end
  
end