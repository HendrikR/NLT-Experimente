# saves data as .tga + .json/.yaml for the metadata
# TODO: maybe put this all in a directory / zipped archive with standard names?

# TODO: should do basic sanity checks from images.rb somewhere

require './images.rb'

class TGA < Image
  attr_accessor :compression

  def initialize()
    @compression = :raw
  end
  def write(filename)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::BINARY)
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
    file.write08 0x00 # attribute bits - 0 for now

    file.write @name

    for p in @palette do
      file.write [p.b, p.g, p.r].pack("CCC")
    end

    # TODO: support RLE compression
    packed_data = compress(@data)
    file.write packed_data.pack("C*")
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
    for i in 0...data.size
      c = data[i]
      if c <= 0x7F
        out << c
      else
        len = c - 0x7F
        i += 1
        c = data[i]
        len.times{ out << c }
      end
    end
    return out
  end

  def compress_rle(data)
    # TODO: stop after out.size >= @dimensions.size?
    out       = []
    last_byte = data[0]
    seq_len   = 0
    i         = 0
    while i < data.size
      c = data[i]
      if c == last_byte && c < 0x80 && seq_len < 255
        seq_len += 1
      else
        if seq_len < 2
          seq_len.times{ out << c }
        else
          out << 0x7F << seq_len << last_byte
        end
        last_byte = c
        seq_len = 1
      end
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

    raise("TGA images without palette not supported") if tga_pal_type != 1
    raise("Only indexed images (type 1 and 9) supported") if tga_img_type % 8 != 1
    raise("Only type 1 (uncompressed) and type 9 (rle compressed) TGA images supported") if tga_img_type != 1 && tga_img_type != 9
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
    raw_data = file.read(@dimensions.width*@dimensions.height).unpack("C*")
    @data = decompress(raw_data)

    # cut off any metadata / cruft after the data
    if @data.size > @dimensions.size
      @data.slice(0, @dimensions.size)
    end
  end
end
