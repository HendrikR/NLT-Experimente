require './images.rb'
require './compression.rb'

class NVF < ImageHandler
  def uniform_resolution?(nvf)
    # formats 0, 2, 4 have the same resolution for all subimages.
    # formats 1, 3, 5 have their own resolutions for subimages.
    return nvf.subformat % 2 == 0
  end

  def compression_mode(nvf)
    # modes 0,1: no compression
    # modes 2,3: Amiga PowerPack 2.0
    # modes 4,5: RLE (Variante 1: 0x7F als RLE-Marker)
    case nvf.subformat / 2
    when 0; :raw
    when 1; :pp
    when 2; :rle1
    else raise("unknown NVF mode #{nvf.subformat}")
    end
  end

  def write(filename, nvf)
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write08 nvf.subformat
    file.write16 nvf.images.size

    for img in nvf.images do img.compressed_data = compress(img.data, compression_mode(nvf)); end
    if uniform_resolution?(nvf)
      file.write16 nvf.dimensions.width
      file.write16 nvf.dimensions.height
      for img in nvf.images do
        file.write32 img.compressed_data.size
      end
    else
      for img in nvf.images do
        file.write16 img.dimensions.width
        file.write16 img.dimensions.height
        file.write32 img.compressed_data.size
      end
    end
    for img in nvf.images do
      file.write img.compressed_data.pack("C*")
    end
    # Color Palette
    file.write16 nvf.palette.size
    nvf.palette.each{|c|
      file.write [c.r >> 2, c.g >> 2, c.b >> 2].pack("CCC")
    }
    file.close
  end

  def read(filename)
    nvf = ImageList.new
    file =  File.open(filename, IO::BINARY)
    nvf.subformat = file.read08
    raise("invalid NVF compression mode") if compression_mode(nvf) == nil
    img_size = file.read16
    raise("Error: Empty NVF image") if img_size == 0
    nvf.images  = []
    nvf.palette = []

    puts "reading mode #{nvf.subformat} NVF with #{img_size} images"
    if uniform_resolution?(nvf)
      nvf.dimensions = Rect.new(0,0, file.read16, file.read16)
      puts "uniform image resolution of #{nvf.dimensions}"
      img_size.times do
        img = Image.new
        img.dimensions = nvf.dimensions
        img.palette = nvf.palette
        img.data = file.read32 # misuse the nvf.data field for the size of compressed data
        if compression_mode(nvf) == :raw then img.data = img.dimensions.size; end
        nvf.images << img
      end
    else
      img_size.times do
        img = Image.new
        img.dimensions = Rect.new(0,0, file.read16, file.read16 & 0xFF)
        img.palette = nvf.palette
        img.data = file.read32 # misuse the nvf.data field for the size of compressed data
        if compression_mode(nvf) == :raw then img.data = img.dimensions.size; end
        nvf.images << img
      end
      nvf.dimensions = Rect.new(0,0,
                                nvf.images.map{|img| img.dimensions.width }.max,
                                nvf.images.map{|img| img.dimensions.height}.max
                               )
    end
    for img in nvf.images do
      img.compressed_data = file.read( img.data ).unpack("C*")
      raise("reading failed") if img.compressed_data.size != img.data
      img.data = decompress( img.compressed_data, compression_mode(nvf) )
    end

    # Read color palette
    file.seek(file.size - 3*256-2)
    palette_size = file.read16
    raise "Error: invalid palette size #{palette_size}" if palette_size > 256
    palette_size.times do
      rgb = file.read(3).unpack("CCC")
      nvf.palette << Palette.new(rgb[0] << 2, rgb[1] << 2, rgb[2] << 2)
    end
    file.close
    return nvf
  end
end
