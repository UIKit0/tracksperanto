# An accumulator buffer for Ruby objects. Use it to sequentially store a shitload
# of objects on disk and then retreive them one by one. Make sure to call clear when done
# with it to discard the stored blob. It can be used like a disk-based object buffer.
# (Tracksperanto stores parsed trackers into it)
#
#  a = Tracksperanto::Accumulator.new
#  parse_big_file do | one_node |
#    a.push(one_node)
#  end
#
#  a.size #=> 30932 # We've stored 30 thousand objects on disk without breaking a sweat
#  a.each do | node_read_from_disk |
#     # do something with node that has been recovered from disk
#  end
#
#  a.clear # ensure that the file is deleted
class Tracksperanto::Accumulator
  include Enumerable
  
  # Returns the number of objects stored so far
  attr_reader :size
  
  def initialize
    @store = Tracksperanto::BufferIO.new
    @size = 0
    
    super
  end
  
  def empty?
    @size.zero?
  end
  
  # Store an object
  def push(object_to_store)
    blob = marshal_object(object_to_store)
    @store.write(blob)
    @size += 1
    
    object_to_store
  end
  
  alias_method :<<, :push
  
  # Retreive each stored object in succession. All other Enumerable
  # methods are also available (but be careful with Enumerable#map and to_a)
  def each
    # We first ensure that we have a disk-backed file, then reopen it as read-only
    # and iterate through that (we will have one IO handle per loop nest)
    iterable = File.open(@store.to_file.path, "r")
    @size.times { yield(recover_object_from(iterable)) }
  ensure
    iterable.close
  end
  
  # Calls close! on the datastore and deletes the objects in it
  def clear
    @store.close!
    @size = 0
  end
  
  private
  
  def marshal_object(object_to_store)
    d = Marshal.dump(object_to_store)
    blob = [d.size, "\t", d, "\n"].join
  end
  
  def recover_object_from(io)
    # Up to the tab is the amount of bytes to read
    demarshal_bytes = io.gets("\t").to_i
    blob = io.read(demarshal_bytes)
    
    Marshal.load(blob)
  end
end
