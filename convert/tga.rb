# TODO: should do basic sanity checks from images.rb somewhere

require './images.rb'

COMPRESSIONS = {:raw => 0, :rle2 => 8 }

class TGA < Image
  def initialize()
    @subformat = 0
  end

  def compression_mode
    case @subformat
    when 1; :raw    # mode 1: indexed, uncompressed
    when 9; :rle2   # mode 9: indexed, RLE compressed
    else raise("unsupported TGA format #{@subformat}")
    end
  end

  def compression_mode_id(mode)
    case mode
    when :raw;  1   # mode 1: indexed, uncompressed
    when :rle2; 9   # mode 9: indexed, RLE compressed
    else raise("unsupported TGA format #{mode}")
    end
  end

  def write(filename)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    raise "image name too long (>255 bytes)" if @name.size > 255
    file.write08 @name.size
    file.write08 1 # image has color palette
    file.write08 @subformat
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

    @compressed_data = compress(@data, compression_mode)
    file.write @compressed_data.pack("C*")
    file.close
  end

  def read(filename)
    file = File.open(filename, IO::BINARY)
    tga_name_len       = file.read08()
    tga_pal_type       = file.read08()
    @subformat         = file.read08()
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
    @data = decompress(@compressed_data, compression_mode)

    # cut off any metadata / cruft after the data
    if @data.size > @dimensions.size
      puts "cutting of #{@data.size-@dimensions.size} bytes after #{@dimensions.size}"
      @data.slice!(0, @dimensions.size)
    end
  end
end
