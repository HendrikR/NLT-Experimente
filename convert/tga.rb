# saves data as .tga + .json/.yaml for the metadata
# TODO: maybe put this all in a directory / zipped archive with standard names?

# TODO: should do basic sanity checks from images.rb somewhere

require 'images.rb'

class TGA < Image
  def write(filename)
    file =  File.open(filename, IO::CREATE | IO::WRONLY | IO::BINARY)
    raise "image name too long (>255 bytes)" if @name.size < 256
    file.write08 @name.size
    file.write08 1 # image has color palette
    file.write08 1 # image type 1 -- indexed uncompressed (TODO: support type 9 (RLE compression))
    file.write16 17 + @name.size # offset of palette data
    file.write16 256 # our palette always has 256 colors
    file.write08 24 # bits per palette entry: 8 for b,g,r
    file.write16 @clip_rect.x0
    file.write16 @clip_rect.y0
    file.write16 @clip_rect.width
    file.write16 @clip_rect.height
    file.write08 0x00 # attribute bits - 0 for now

    file.write @name
    for p in @palette do
      file.write [p.b, p.g, p.r].pack("CCC")
    end

    # TODO: support RLE compression?
    file.write @data.pack("C*")
  end

  def read(filename)
    file = File.open(filename, IO::BINARY)
    tga_id_len        = file.read08()
    tga_pal_type      = file.read08()
    tga_img_type      = file.read08()
    tga_pal_ofs       = file.read16()
    tga_pal_len       = file.read16()
    tga_pal_bits      = file.read08()
    @clip_rect.x0     = file.read16()
    @clip_rect.y0     = file.read16()
    @clip_rect.width  = file.read16()
    @clip_rect.height = file.read16()
    bits_per_pixel    = file.read08()
    tga_attribs       = file.read08()

    raise("TGA images without palette not supported") if tga_pal_type != 1
    raise("Only 24-bit palette indexed images supported") if tga_img_type % 8 != 1
    raise("Only uncompressed images supported (for now)") if tga_img_type / 8 != 0
    raise("Only 8-bit indexed images supported") if bit_per_pixel != 8

    @name   = file.read(tga_id_len)

    # read and convert palette
    file.seek(tga_pal_ofs, IO::SEEK_CUR)
    @palette = []
    tga_pal_data = file.read(tga_pal_len).unpack("C*")
    tga_pal_len.times do
      b,g,r = file.read(3).unpack("CCC")
      @palette << Palette.new(r,g,b)
    end

    # read image data
    @data = file.read(@clip_rect.width*@clip_rect.height).unpack("C*")
    # TODO: support (RLE-)compressed data
    # TODO: what about metadata following the image data?
  end
end
