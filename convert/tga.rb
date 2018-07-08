# TODO: should do basic sanity checks from images.rb somewhere

require './images.rb'

class TGA < ImageHandler
  def compression_mode(tga)
    case tga.subformat
    when 1; :raw    # mode 1: indexed, uncompressed
    when 9; :rle2   # mode 9: indexed, RLE compressed
    else raise("unsupported TGA format #{tga.subformat}")
    end
  end

  def self.compression_mode_id(mode)
    case mode
    when :raw;  1   # mode 1: indexed, uncompressed
    when :rle2; 9   # mode 9: indexed, RLE compressed
    else raise("unsupported TGA format #{mode}")
    end
  end

  def write(filename, tga)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    raise "image name too long (>255 bytes)" if tga.name.size > 255
    file.write08 tga.name.size
    file.write08 1 # image has color palette
    file.write08 tga.subformat
    file.write16 0 # extra offset of palette data. TODO: add tga.name.size or not?
    file.write16 tga.palette.size # our palette always has 256 colors (see sanity checks)
    file.write08 24 # bits per palette entry: 8 for b,g,r
    file.write16 tga.dimensions.x0
    file.write16 tga.dimensions.y0
    file.write16 tga.dimensions.width
    file.write16 tga.dimensions.height
    file.write08 8 # bits per pixel
    file.write08 (0<<4) | (1<<5) # attribute bits -- set bits 4:=0, 5:=1 to indicate that (0,0) is top-left

    file.write tga.name

    for p in tga.palette do
      file.write [p.b, p.g, p.r].pack("CCC")
    end

    tga.compressed_data = compress(tga.data, compression_mode(tga))
    file.write tga.compressed_data.pack("C*")
    file.close
  end

  def read(filename)
    tga = Image.new
    file = File.open(filename, IO::BINARY)
    tga_name_len       = file.read08()
    tga_pal_type       = file.read08()
    tga.subformat         = file.read08()
    tga_pal_ofs        = file.read16()
    tga_pal_len        = file.read16()
    tga_pal_bits       = file.read08()
    tga.dimensions        = Rect.new(0,0,0,0)
    tga.dimensions.x0     = file.read16()
    tga.dimensions.y0     = file.read16()
    tga.dimensions.width  = file.read16()
    tga.dimensions.height = file.read16()
    bits_per_pixel     = file.read08()
    tga_attribs        = file.read08()

    raise("TGA images without palette not supported") if tga_pal_type != 1
    raise("Only 8-bit indexed images with 24-bit palette supported") if tga_pal_bits != 24 or bits_per_pixel != 8

    tga.name   = file.read(tga_name_len)

    # read and convert palette
    file.seek(tga_pal_ofs, IO::SEEK_CUR)
    tga.palette = []
    tga_pal_len.times do
      b,g,r = file.read(3).unpack("CCC")
      tga.palette << Palette.new(r,g,b)
    end

    # read image data
    tga.compressed_data = file.read().unpack("C*")
    tga.data = decompress(tga.compressed_data, compression_mode(tga))

    # cut off any metadata / cruft after the data
    if tga.data.size > tga.dimensions.size
      puts "cutting of #{tga.data.size-tga.dimensions.size} bytes after #{tga.dimensions.size}"
      tga.data.slice!(0, tga.dimensions.size)
    end
    return tga
  end
end
