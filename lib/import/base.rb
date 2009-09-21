# The base class for all the import modules. By default, when you inherit from this class the inherited class will be included
# in the list of supported Tracksperanto importers. The API that an importer should present is very basic, and consists only of a few methods.
# The main method is parse(io) which should return an array of Tracker objects.
class Tracksperanto::Import::Base
  include Tracksperanto::Safety
  include Tracksperanto::Casts
  include Tracksperanto::BlockInit
  include Tracksperanto::ZipTuples
  include Tracksperanto::ConstName
  
  # Tracksperanto will assign a proc that reports the status of the import to the caller.
  # This block is automatically used by report_progress IF the proc is assigned. Should
  # the proc be nil, the report_progress method will just pass (so you don't need to check for nil
  # yourself)
  attr_accessor :progress_block
  
  # The original width of the tracked image.
  # If you need to know the width for your specific format and cannot autodetect it,
  # Trakcksperanto will assign the passed width and height to the importer object before running
  # the import. If not, you can replace the assigned values with your own. At the end of the import
  # procedure, Tracksperanto will read the values from you again and will use the read values
  # for determining the original comp size. +width+ and +height+ MUST return integer values after
  # the import completes
  attr_accessor :width
  
  # The original height of the comp, same conventions as for width apply
  attr_accessor :height
  
  # These reader methods will raise when the values are nil
  cast_to_int :width, :height
  safe_reader :width, :height
  
  # Used to register your importer in the list of supported formats.
  # Normally you would not need to override this
  def self.inherited(by)
    Tracksperanto.importers << by
    super
  end
  
  # Return an extension WITH DOT if this format has a typical extension that
  # you can detect 
  def self.distinct_file_ext
    nil
  end
  
  # Should return a human-readable (read: properly capitalized and with spaces) name of the
  # import format
  def self.human_name
    "Abstract import format"
  end
  
  # Return true from this method if your importer can deduce the comp size from the passed file
  def self.autodetects_size?
    false
  end
  
  # Call this method to tell what you are doing. This gets propagated to the caller automatically, or
  # gets ignored if the caller did not request any progress reports
  def report_progress(message)
    @progress_block.call(message) if @progress_block
  end
  
  # The main method of the parser. Will receive an IO handle to the file being imported, and should
  # return an array of Tracksperanto::Tracker objects containing keyframes. If you have a problem
  # doing an import, raise from here.
  def parse(track_file_io)
    []
  end
end