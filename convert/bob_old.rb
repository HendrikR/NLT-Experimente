require './images.rb'

class BOB_OLD < ImageHandler
  def read(filename)
    bob  = ImageGroup.new
    file = File.open(filename, IO::BINARY)
    header_size    = file.read32
    palette_offs   = file.read32 # TODO: verify, but seems to always be 770 bytes before end
    bob.dimensions = Rect.new(0,0, file.read16, file.read08 )
    num_groups     = file.read08
    group_hdr_ofs  = []
    num_groups.times{
      group_hdr_ofs << file.read32
    }
    group_hdr_ofs << header_size # add last offset for easier handling (see below)
    # read partial animation header

    for i in 0...num_groups do
      file.seek(group_hdr_ofs[i])
      raise "ERROR: wrong place #{file.tell} != #{group_hdr_ofs[i]}" if file.tell != group_hdr_ofs[i]
      part = ImageList.new
      part.name = file.read(4).unpack("a*")[0]
      dims = file.read(5).unpack("SCCC")
      part.dimensions = Rect.new(dims[0], dims[1], dims[3], dims[2])
      unk01           = file.read16
      while file.tell < group_hdr_ofs[i+1] # read until at end of subheader
        num_frames = file.read08
        raise "#{num_frames} frames is strange" if num_frames > 60 # TODO: remove when algorithms runs correct
        num_frames.times{
          unk02 = file.read(4).unpack("CCCC") # TODO: what is this? maybe ?, subimage_idx, ?, show_duration
          # Nur eine Vermutung
          puts "Show #{part.name}[#{unk02[1]}] for #{unk02[3]} ticks: #{unk02}"
        }
      end
      bob.parts << part
    end

    # TODO: read individual images
    # Looks like they are all pp-compressed.
    file.close
    return bob
  end

  def write(filename, bob)
    file = File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)

    file.close
  end
end
