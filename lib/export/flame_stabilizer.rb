# TODO: this exporter is MAJORLY slow now
class Tracksperanto::Export::FlameStabilizer < Tracksperanto::Export::Base
  
  COLOR = "50 50 50"
  DATETIME_FORMAT = '%a %b %d %H:%M:%S %Y'
  
  def self.desc_and_extension
    "flame.stabilizer"
  end
  
  def self.human_name
    "Flame/Smoke 2D Stabilizer setup"
  end
  
  def start_export( img_width, img_height)
    @counter = 0
    @width, @height = img_width, img_height
    @temp = Tracksperanto::BufferIO.new
    @writer = Tracksperanto::FlameBuilder.new(@temp)
  end
  
  def end_export
    # Now make another writer, this time for our main IO
    @writer = Tracksperanto::FlameBuilder.new(@io)
    
    # Now we know how many trackers we have so we can write the header
    # data along with NbTrackers
    write_header_with_number_of_trackers(@counter)
    
    # Now write everything that we accumulated earlier into the base IO
    @temp.rewind
    @io.write(@temp.read) until @temp.eof?
    @temp.close!
    
    # Send the ChannelEnd command and list the trackers
    @writer.channel_end
    @counter.times do |i|
      @writer.tracker(i) do |t|
        t.active true
        t.color_hash!("colour", 0, 100, 0)
        t.fixed_ref true
        t.fixed_x false
        t.fixed_y false
        t.tolerance 100
      end
    end
  end
  
  def start_tracker_segment(tracker_name)
    @counter += 1
    @write_first_frame = true
  end
  
  def export_point(frame, abs_float_x, abs_float_y, float_residual)
    flame_frame = frame + 1
    if @write_first_frame
      @base_x, @base_y = abs_float_x, abs_float_y
      write_first_frame(abs_float_x, abs_float_y)
      # For Flame to recognize the reference frame of the Shift channel
      # we need it to contain zero as an int, not as a float. The shift proceeds
      # from there.
      @x_shift_values = [[flame_frame, 0]]
      @y_shift_values = [[flame_frame, 0]]
      @write_first_frame = false
    else
      # Just continue buffering the upcoming shift keyframes and flush them in the end
      shift_x, shift_y = @base_x - abs_float_x, @base_y - abs_float_y
      @x_shift_values.push([flame_frame, shift_x])
      @y_shift_values.push([flame_frame, shift_y])
    end
  end
  
  def end_tracker_segment
    # We write these at tracker end since we need to know in advance
    # how many keyframes they should contain
    write_shift_channel("shift/x", @x_shift_values)
    write_shift_channel("shift/y", @y_shift_values)
  end
  
  private
  
  def generate_fragment
    c = StringIO.new
    yield(Tracksperanto::FlameBuilder.new(c))
    c.string
  end
  
  # The shift channel is what determines how the tracking point moves.
  def write_shift_channel(name_without_prefix, values)
    @writer.channel(replace_tracker_name("tracker1/#{name_without_prefix}")) do | c |
      c.extrapolation :constant
      c.value values[0][1]
      c.key_version 1
      c.size values.length
      values.each_with_index do | (f, v), i |
        # Cache the fragment used for the keyframe
        @shift_key ||= generate_fragment do | b |
          b.key(:keyIDX) do | k |
            k.frame :theF
            k.value :theV
            k.interpolation :linear
            k.left_slope 2.4
            k.right_slope 2.4
          end
        end
        v = i.zero? ? "0" : "%.3f" % v
        c << @shift_key.gsub(/theF/m, f.to_s).gsub(/theV/m, v).gsub(/keyIDX/m, i.to_s)
      end
    end
  end
  
  def write_header_with_number_of_trackers(number_of_trackers)
    @writer.stabilizer_file_version "5.0"
    @writer.creation_date(Time.now.strftime(DATETIME_FORMAT))
    @writer.linebreak!(2)
    
    @writer.nb_trackers number_of_trackers
    @writer.selected 0
    @writer.frame_width @width
    @writer.frame_height @height
    @writer.auto_key true
    @writer.motion_path true
    @writer.icons true
    @writer.auto_pan false # hate it!
    @writer.edit_mode 0
    @writer.format 0
    @writer.color_hash!("padding", 0, 100, 0)
    @writer.oversampling false
    @writer.opacity 50
    @writer.zoom 3
    @writer.field false
    @writer.backward false
    @writer.anim
  end
  
  def write_first_frame(x, y)
    write_track_channels
    write_track_width_and_height
    write_ref_width_and_height
    write_ref_channels(x, y)
    write_deltax_and_deltay_channels
    write_offset_channels
  end
  
  
  # track determines where the tracking box is, and should be in the center
  # of the image for Flame to compute all other shifts properly
  def write_track_channels
    @track_channels ||= generate_fragment do | b |
      ctr_x, ctr_y = @width / 2, @height / 2
      %w( tracker1/track/x tracker1/track/y).zip([ctr_x, ctr_y]).each do | cname, default |
        b.channel(cname) do | c |
          c.extrapolation("constant")
          c.value(default.to_i)
          c.colour(COLOR)
        end
      end
    end
    @writer << replace_tracker_name(@track_channels)
  end

  # The size of the tracking area
  def write_track_width_and_height
    @track_w_h ||= generate_fragment do | b |
      %w( tracker1/track/width tracker1/track/height ).each do | channel_name |
        b.channel(channel_name) do | c |
          c.extrapolation :linear
          c.value 15
          c.colour COLOR
        end
      end
    end
    @writer << replace_tracker_name(@track_w_h)
  end
  
  # The size of the reference area
  def write_ref_width_and_height
    @ref_w_h ||= generate_fragment do | b |
      %w( tracker1/ref/width tracker1/ref/height).each do | channel_name |
        b.channel(channel_name) do | c |
          c.extrapolation :linear
          c.value 10
          c.colour COLOR
        end
      end
    end
    @writer << replace_tracker_name(@ref_w_h)
  end
  
  # The Ref channel contains the reference for the shift channel in absolute
  # coordinates, and is set as float. Since we do not "snap" the tracker in
  # the process it's enough for us to make one keyframe in the ref channels
  # at the same frame as the first shift keyframe
  def write_ref_channels(ref_x, ref_y)
    @ref_chan ||= generate_fragment do | b |
      %w( tracker1/ref/x tracker1/ref/y).zip(["vx", "vy"]).each do | cname, default |
        b.channel(cname) do | c |
          c.extrapolation("constant")
          c.value(default)
          c.colour(COLOR)
          c.key_version 1
          c.size 1
          c.key(0) do | k |
            k.frame 1
            k.value default
            k.interpolation :constant
            k.left_slope 2.4
            k.right_slope 2.4
          end
        end
      end
    end
    ref_x, ref_y = [ref_x, ref_y].map{|e| "%.3f" % e }
    @writer << replace_tracker_name(@ref_chan).gsub(/vx/m, ref_x).gsub(/vy/, ref_y)
  end
  
  # This is used for deltax and deltay (offset tracking).
  # We set it to zero and lock
  def write_deltax_and_deltay_channels
    @dx_dy ||= generate_fragment do | b |
      %w( tracker1/ref/dx tracker1/ref/dy).each do | chan, v |
        b.channel(chan) do | c |
          c.extrapolation("constant")
          c.value 0
          c.colour(COLOR)
          c.size 2
          c.key_version 1
          c.key(0) do | k |
            k.frame 0
            k.value 0
            k.value_lock true
            k.delete_lock true
            k.interpolation :constant
          end
          c.key(1) do | k |
            k.frame 1
            k.value 0
            k.value_lock true
            k.delete_lock true
            k.interpolation :constant
          end
        end # Chan block
      end
    end
    
    @writer << replace_tracker_name(@dx_dy)
  end
  
  def write_offset_channels
    @offset ||= generate_fragment do | b |
      %w(tracker1/offset/x tracker1/offset/y).each do | c |
        @writer.channel(c) do | chan |
          chan.extrapolation :constant
          chan.value 0
        end
      end
    end
    @writer << replace_tracker_name(@offset)
  end
  
  def replace_tracker_name(in_str)
    in_str.gsub(/tracker1/m, "tracker#{@counter}")
  end
end
