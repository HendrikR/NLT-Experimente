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
    bitmap = decompress(file.read.unpack("C*"), :uli)

    # Palette is compressed using the same algorithm
    palette_data = bitmap.shift(3*palette_size)
    palette_size.times{|i|
      uli.palette[i] = Palette.new(palette_data.shift << 2, palette_data.shift << 2, palette_data.shift << 2)
    }

    if palette_size <= 16 # Palette is small enough to fit several indices in 1 byte
      uli.data = []
      udl = Math.log2(palette_size).ceil()
      udl = 2 ** Math.log2(udl).ceil # make result fit straight into 1 byte (i.e. 1,2,4 bits)
      bit_mask = 2**udl - 1 # 0b1 for udl==1, 0b11 for udl==2, 0b1111 for udl==4
      sectors = 8/udl       # number of pixels encoded in a bit
      bitmap.each{|byte|
        sectors.times{|i|
          bit_shift = udl * ((sectors-1) - i) # 
          uli.data << ( (byte >> bit_shift) & bit_mask )
        }
      }
    else
      uli.data = bitmap
    end
    raise "invalid size: #{uli.data.size} vs #{uli.dimensions.size}" if uli.data.size != uli.dimensions.size
    
    file.close
    return uli
  end

  def write(filename, uli)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write(MAGIC_STRING)
    file.write("\x1A\x00\x85") # some unknown bytes
    file.write16(uli.dimensions.width - 1)
    file.write16(uli.dimensions.height - 1)
    file.write08(uli.palette.size)

    # compress and write palette data
    palette_data = uli.palette.map{|x| x.to_a}.flatten
    # TODO respect bit-compression for small palettes
    compressed = compress(palette_data + uli.data, :uli)
    puts "ULI size down from #{(palette_data + uli.data).size} to #{compressed.size}"
    exit
    
    file.write compressed.pack("C*")
    file.close
  end
end

