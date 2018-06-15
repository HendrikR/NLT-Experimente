# TODO: should do basic sanity checks from images.rb somewhere

require './images.rb'

COMPRESSIONS = {:raw => 0, :rle => 8 }

class TGA < Image
  attr_accessor :compression

  def initialize()
    @compression = :raw
  end
  def write(filename)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    raise "image name too long (>255 bytes)" if @name.size > 255
    file.write08 @name.size
    file.write08 1 # image has color palette
    case(@compression)
    when :raw; file.write08 1 # image type 1 -- indexed, uncompressed
    when :rle; file.write08 9 # image type 9 -- indexed, RLE compressed
    else raise "unknown compression mode #{@compression}."
    end
    file.write16 0 # extra offset of palette data. TODO: add @name.size or not?
    file.write16 @palette.size # our palette always has 256 colors (see sanity checks)
    file.write08 24 # bits per palette entry: 8 for b,g,r
    file.write16 @dimensions.x0
    file.write16 @dimensions.y0
    file.write16 @dimensions.width
    file.write16 @dimensions.height
    file.write08 8 # bits per pixel
    file.write08 (0<<4) | (1<<5) # attribute bits -- set bits 4:=0, 5:=1 to indicate that (0,0) is top-left

    file.write @name

    for p in @palette do
      file.write [p.b, p.g, p.r].pack("CCC")
    end

    @compressed_data = compress(@data)
    file.write @compressed_data.pack("C*")
    file.close
  end


  def decompress(packed_data)
    case(@compression)
    when :raw; return packed_data
    when :rle; return decompress_rle(packed_data)
    else raise "unknown compression mode #{@compression}."
    end
  end

  def compress(plain_data)
    case(@compression)
    when :raw; return plain_data
    when :rle; return compress_rle(plain_data)
    else raise "unknown compression mode #{@compression}."
    end
  end

  def decompress_rle(data)
    out = []
    i = 0
    while i < data.size
      block_len = (data[i] & 0x7F) + 1 # run length is lower 7 bits plus 1
      if data[i] < 0x80 # raw block of *block_len* pixels
        block_len.times{ i+=1; out << data[i] }
      else # > 0x80 -- repeat next pixel *block_len* times
        i+= 1
        block_len.times{ out << data[i] }
      end
      i += 1
    end
    return out
  end

  def compress_rle(data)
    # TODO: stop after out.size >= @dimensions.size?
    out       = []
    i = 0
    uhu = 0
    while i < data.size
      col = data[i]
      seq_len = 1
      while seq_len < 128 && i+seq_len < data.size && data[i+seq_len] == col do seq_len+=1; end
      if seq_len > 1
        out << ((seq_len-1) | 0x80)
        out << col
      else # raw pixels
        seq_len = i+128 < data.size ? 128 : (data.size-i)
        uhu += seq_len
        out << seq_len - 1
        seq_len.times { |j| out << data[i+j] }
      end
      i += seq_len
    end
    return out
  end

  def read(filename)
    file = File.open(filename, IO::BINARY)
    tga_name_len       = file.read08()
    tga_pal_type       = file.read08()
    tga_img_type       = file.read08()
    tga_pal_ofs        = file.read16()
    tga_pal_len        = file.read16()
    tga_pal_bits       = file.read08()
    @dimensions        = Rect.new(0,0,0,0)
    @dimensions.x0     = file.read16()
    @dimensions.y0     = file.read16()
    @dimensions.width  = file.read16()
    @dimensions.height = file.read16()
    bits_per_pixel     = file.read08()
    tga_attribs        = file.read08()

    case(tga_img_type)
    when 1; @compression = :raw
    when 9; @compression = :rle
    else raise("Only type 1 (uncompressed) and type 9 (rle compressed) TGA images supported")
    end
    raise("TGA images without palette not supported") if tga_pal_type != 1
    raise("Only indexed images (type 1 and 9) supported") if tga_img_type % 8 != 1
    raise("Only 8-bit indexed images with 24-bit palette supported") if tga_pal_bits != 24 or bits_per_pixel != 8

    @name   = file.read(tga_name_len)

    # read and convert palette
    file.seek(tga_pal_ofs, IO::SEEK_CUR)
    @palette = []
    tga_pal_len.times do
      b,g,r = file.read(3).unpack("CCC")
      @palette << Palette.new(r,g,b)
    end

    # read image data
    @compressed_data = file.read().unpack("C*")
    @data = decompress(@compressed_data)

    # cut off any metadata / cruft after the data
    if @data.size > @dimensions.size
      puts "cutting of #{@data.size-@dimensions.size} bytes after #{@dimensions.size}"
      @data.slice!(0, @dimensions.size)
    end
  end
end
