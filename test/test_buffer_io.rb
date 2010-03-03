require File.dirname(__FILE__) + '/helper'

class TestBufferIO < Test::Unit::TestCase
  
  def test_write_in_mem_has_a_stringio
    io = Tracksperanto::BufferIO.new
    9000.times { io.write("a") }
    assert_kind_of StringIO, io.__getobj__
    assert_nothing_raised { io.close! }
  end
  
  def test_write_larger_than_max_swaps_tempfile
    io = Tracksperanto::BufferIO.new
    110_000.times { io.write("a") }
    f = io.__getobj__
    assert_kind_of Tempfile, f
    f.rewind
    assert_equal 110_000, f.read.length
    flexmock(f).should_receive(:close!).once
    io.close!
  end
end