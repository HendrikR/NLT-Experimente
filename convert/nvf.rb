require './images.rb'
require './compression.rb'

class NVF < ImageList
  def uniform_resolution?
    # formats 0, 2, 4 have the same resolution for all subimages.
    # formats 1, 3, 5 have their own resolutions for subimages.
    return @subformat % 2 == 0
  end

  def compression_mode
    # modes 0,1: no compression
    # modes 2,3: Amiga PowerPack 2.0
    # modes 4,5: RLE (Variante 1: 0x7F als RLE-Marker)
    case @subformat / 2
    when 0; :raw
    when 1; :pp
    when 2; :rle1
    else raise("unknown NVF mode #{@subformat}")
    end
  end

  def write(filename)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write08 @subformat
    file.write16 @images.size

    for img in @images do img.compressed_data = compress(img.data, compression_mode); end
    if uniform_resolution?
      file.write16 @dimensions.width
      file.write16 @dimensions.height
      for img in @images do
        file.write32 img.compressed_data.size
      end
    else
      for img in @images do
        file.write16 img.dimensions.width
        file.write16 img.dimensions.height
        file.write32 img.compressed_data.size
      end
    end
    for img in @images do
      file.write img.compressed_data.pack("C*")
    end
    # Color Palette
    file.write16 @palette.size
    @palette.each{|c|
      file.write [c.r, c.g, c.b].pack("CCC")
    }
    file.close
  end

  def read(filename)
    file =  File.open(filename, IO::BINARY)
    @subformat = file.read08
    raise("invalid NVF compression mode") if compression_mode == nil
    img_size = file.read16
    raise("Error: Empty NVF image") if img_size == 0
    @images  = []
    @palette = []

    puts "reading mode #{@subformat} NVF with #{img_size} images"
    if uniform_resolution?
      @dimensions = Rect.new(0,0, file.read16, file.read16)
      img_size.times do
        img = Image.new
        img.dimensions = @dimensions
        img.palette = @palette
        img.data = file.read32 # misuse the @data field for the size of compressed data
        @images << img
      end
    else
      img_size.times do
        img = Image.new
        img.dimensions = Rect.new(0,0, file.read16, file.read16)
        img.palette = @palette
        img.data = file.read32 # misuse the @data field for the size of compressed data
        @images << img
      end
      @dimensions = @images[0].dimensions
    end
    for img in @images do
      img.compressed_data = file.read( img.data ).unpack("C*")
      raise("reading failed") if img.compressed_data.size != img.data
      img.data = decompress( img.compressed_data, compression_mode )
    end

    # Read color palette
    palette_size = file.read16
    raise "Error: invalid palette size #{palette_size}" if palette_size > 256
    palette_size.times do
      rgb = file.read(3).unpack("CCC")
      @palette << Palette.new(rgb[0], rgb[1], rgb[2])
    end
    file.close
  end
end
