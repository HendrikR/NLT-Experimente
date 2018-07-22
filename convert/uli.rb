# coding: utf-8
require './images.rb'
require './compression.rb'

class ULI < ImageHandler
  MAGIC_STRING = "(C) 1991 by Ulrich Walther"
  
  def compression_mode(uli)
    case uli.subformat
    when 0; raise "nö"
    else raise("unsupported ULI format #{uli.subformat}")
    end
  end

  def self.compression_mode_id(mode)
    case mode
    when 0; raise "nä"
    else raise("unsupported ULI format #{mode}")
    end
  end

  def write(filename, uli)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    # TODO
    file.close
  end

  def read(filename)
    # TODO
    uli = Image.new
    file = File.open(filename, IO::BINARY)

    magic   = file.read(MAGIC_STRING.length)
    raise "Error: invalid ULI format identifier '#{magic}'" if magic != MAGIC_STRING
    unk02 = file.read(3).unpack("CCC") # 0x1A0085 for all images
    raise "unexpected unk02" if unk02 != [0x1A, 0x00, 0x85]
    uli.dimensions = Rect.new(0,0, file.read16 + 1, file.read16 + 1) # This is the same for every image
    palette_size = file.read08
    puts "ULI has #{palette_size} palette entries"

    # read compressed palette & image data
    uli.compressed_data = file.read.unpack("C*")
    i = 0
    bitmap = []
    while i < uli.compressed_data.size
      len = uli.compressed_data[i]
      i+= 1
      if len < 0x80
        color = uli.compressed_data[i]
        len.times{ bitmap << color }
        i += 1
      else
        len -= 0x80
        len.times{
          bitmap << uli.compressed_data[i]
          i+= 1
        }
      end
    end

    # Palette is compressed using the same algorithm
    palette_data = bitmap.shift(3*palette_size)
    palette_size.times{|i|
      uli.palette[i] = Palette.new(palette_data.shift << 2, palette_data.shift << 2, palette_data.shift << 2)
    }
    #(255-palette_size).times{|i| uli.palette[i+palette_size] = Palette.new(0,0,255) } # Dummy-Einträge
    uli.data = []
    if palette_size <= 2
      bitmap.each{|byte|
        8.times{|i| uli.data << (byte >> (7-i) & 0b1) }
      }
    elsif palette_size <= 4
      bitmap.each{|byte|
        4.times{|i| uli.data << (byte >> (2*(3-i)) & 0b11) }
      }
    elsif palette_size <= 16
      bitmap.each{|byte|
        2.times{|i| uli.data << (byte >> (4*(1-i)) & 0b1111) }
      }
    else
      uli.data = bitmap
    end
    raise "invalid size: #{uli.data.size} vs #{uli.dimensions.size}" if uli.data.size != uli.dimensions.size
    
    file.close
    return uli
  end
end


def write(filename, uli)
  file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
  file.write(MAGIC_STRING)
  file.write("\x1A\x00\x85") # some unknown bytes
  file.write16(uli.dimensions.width - 1)
  file.write16(uli.dimensions.height - 1)
  file.write08(palette_size)

  # compress and write palette data
  # TODO
  file.write uli.compressed_data.pack("C*")
  file.close
end
