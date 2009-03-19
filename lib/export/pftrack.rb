class Tracksperanto::Export::Pftrack < Tracksperanto::Export::Base
    
    def start_tracker_segment(tracker_name)
      
      # If there was a previous tracker, write it out
      if @prev_tracker && @prev_tracker.any?
        block = [
          "\n",
          @tracker_name.inspect,
          @prev_tracker.length,
          @prev_tracker.join("\n")
        ]
        @io.puts nlock.join("\n")
      end
      
      @prev_tracker = []
      @tracker_name = tracker_name
    end
    
    def export_point(frame, abs_float_x, abs_float_y, float_residual)
      line = "%s %.3f %.3f %.3f" % [frame, abs_float_x, abs_float_y, float_residual]
      @prev_tracker << line
    end
end