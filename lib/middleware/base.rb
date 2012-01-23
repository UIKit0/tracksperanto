# -*- encoding : utf-8 -*-
# The base middleware class works just like a Tracksperanto::Export::Base, but it only wraps another exporting object and does not get registered on it's own
# as an export format. Middleware can be used to massage the tracks being exported in various interesting ways - like moving the coordinates, clipping the keyframes,
# scaling the whole export or even reversing the trackers to go backwards
class Tracksperanto::Middleware::Base
  include Tracksperanto::Casts
  include Tracksperanto::BlockInit
  include Tracksperanto::ConstName
  include Tracksperanto::SimpleExport
  
  # Used to automatically register your middleware in Tracksperanto.middlewares
  # Normally you wouldn't need to override this
  def self.inherited(by)
    Tracksperanto.middlewares.push(by)
    super
  end
  
  # Constructor accepts the exporter that will be wrapped
  def initialize(*exporter_and_args_for_block_init)
    @exporter = exporter_and_args_for_block_init.shift
    super
  end
  
  %w( start_export start_tracker_segment end_tracker_segment
    export_point end_export).each do | m |
    define_method(m){|*a| @exporter.send(m, *a)}
  end

end
