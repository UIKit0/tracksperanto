# Prevents you from exporting invalid trackers
class Tracksperanto::Middleware::Lint < Tracksperanto::Middleware::Base
  class NoTrackersExportedError < RuntimeError
    def message
      "There were no trackers exported"
    end
  end
  
  class EmptyTrackerSentError < RuntimeError
    def initialize(name)
      @name  = name
    end
    
    def message
      "The tracker #{@name} contained no keyframes. Probably there were some filtering ops done and no keyframes have been exported"
    end
  end
  
  def start_export(w, h)
    @trackers = 0
    @keyframes = 0
    @last_tracker_name = nil
    super
  end
  
  def start_tracker_segment(name)
    @last_tracker_name = name
    @keyframes = 0
    super
  end
  
  def export_point(*a)
    @keyframes += 1
    super
  end
  
  def end_tracker_segment
    raise EmptyTrackerSentError.new(@last_tracker_name) if @keyframes.zero?
    @trackers +=1 
    super
  end
  
  def end_export
    raise NoTrackersExportedError if @trackers.zero?
    super
  end
end