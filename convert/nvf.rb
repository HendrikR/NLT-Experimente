# coding: utf-8
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
    # TODO: DSA1:IN_HEADS.NVF hat modus #49, was ist das?
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
        if compression_mode(nvf) != :raw
          file.write32 img.compressed_data.size
        end
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
        if compression_mode(nvf) == :raw
          img.data = img.dimensions.size
        else
          img.data = file.read32  # misuse the nvf.data field for the size of compressed data
        end
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

    # Read color palette (if available)
    if file.size - file.tell == 3*256+2
      palette_size = file.read16
      raise "Error: invalid palette size #{palette_size}" if palette_size > 256
      palette_size.times do
        rgb = file.read(3).unpack("CCC")
        nvf.palette << Palette.new(rgb[0] << 2, rgb[1] << 2, rgb[2] << 2)
      end
      file.close
    else
      puts "WARNING: NVF image without palette"
      SCHICK_TOWNPAL.each{|p| nvf.palette << p}
      #used_colors = {}
      #for i in nvf.images do for pix in i.data do used_colors[pix] = true; end; end
      #puts "used colors: #{used_colors.keys.sort}"
      file.close
    end
    raise "Error: invalid palette size #{nvf.palette.size}" if nvf.palette.size != 256
    return nvf
  end

  # TODO: Find the right palette for every DSA1 image
  # Diese Palette geht (in [0xaa-0xbb] die genutzten Paletten-Indices, 0x00-0x10 implizit):
  # Stadt:    ja.FINGER, HOUSE1-4, LTURM alle [80-A0], TDIVERSE[80-C0], TFLOOR1-2[0-20;9C-A0]
  # Dungeons: no.MARBLESL, SHIPSL, STONESL [80-A0] -- explizit andere Palette.
  # Vollbild: no.FACE[20-50], HYGBACK[20-40], HYGGELIK[20-40], OUTRO1-3[20-40], SKARTE[0-14]
  # Kleines:  no.FIGHTOBJ[61-80], GGSTS[40-5F], GUERTEL[80-9F], OBJECTS[C8-CA], SPELLOBJ[0-1F], WEAPONS[0-1F]
  # Unbekannt:no.IN_HEADS, SPSTAR, SKULL
  SCHICK_TOWNPAL = [
    [0, 0, 0],
    [255, 0, 255],
    [182, 142, 125],
    [170, 130, 117],
    [162, 117, 105],
    [154, 109, 97],
    [142, 97, 89],
    [134, 89, 81],
    [125, 77, 73],
    [113, 69, 65],
    [105, 60, 56],
    [97, 52, 52],
    [16, 130, 0],
    [12, 121, 0],
    [8, 113, 0],
    [4, 105, 0],
    [4, 97, 0],
    [4, 89, 0],
    [0, 81, 0],
    [0, 73, 0],
    [0, 69, 0],
    [0, 60, 0],
    [40, 105, 117],
    [32, 97, 113],
    [28, 85, 105],
    [20, 77, 101],
    [16, 69, 97],
    [12, 56, 93],
    [4, 48, 89],
    [4, 40, 85],
    [0, 32, 81],
    [0, 24, 77],
    [0, 0, 0],
    [0, 0, 255],
    [0, 0, 146],
    [243, 195, 162],
    [243, 178, 146],
    [243, 162, 113],
    [227, 146, 97],
    [211, 130, 81],
    [195, 113, 81],
    [162, 97, 65],
    [146, 81, 48],
    [113, 65, 48],
    [97, 48, 32],
    [81, 48, 32],
    [227, 227, 227],
    [195, 195, 195],
    [178, 178, 178],
    [162, 162, 162],
    [130, 130, 130],
    [113, 113, 113],
    [81, 81, 81],
    [65, 65, 65],
    [0, 255, 0],
    [0, 146, 0],
    [243, 227, 0],
    [211, 178, 0],
    [162, 130, 0],
    [243, 97, 65],
    [195, 65, 32],
    [146, 48, 16],
    [65, 32, 16],
    [243, 243, 243],
    [0, 0, 0],
    [227, 195, 162],
    [195, 146, 113],
    [146, 97, 65],
    [130, 81, 48],
    [97, 48, 32],
    [81, 32, 16],
    [48, 16, 0],
    [243, 227, 0],
    [227, 162, 0],
    [195, 113, 0],
    [178, 81, 0],
    [243, 146, 0],
    [243, 48, 0],
    [243, 0, 32],
    [243, 0, 130],
    [0, 65, 0],
    [0, 81, 0],
    [0, 113, 0],
    [16, 130, 0],
    [16, 162, 0],
    [113, 227, 243],
    [81, 178, 211],
    [48, 113, 195],
    [16, 48, 162],
    [0, 0, 146],
    [65, 65, 65],
    [81, 81, 81],
    [113, 113, 113],
    [146, 146, 146],
    [195, 195, 195],
    [243, 243, 243],
    [0, 0, 0],
    [0, 0, 166],
    [0, 0, 56],
    [154, 105, 73],
    [154, 89, 56],
    [154, 73, 24],
    [138, 56, 8],
    [121, 40, 0],
    [105, 24, 0],
    [73, 8, 0],
    [56, 0, 0],
    [24, 0, 0],
    [8, 0, 0],
    [0, 0, 0],
    [138, 138, 138],
    [105, 105, 105],
    [89, 89, 89],
    [73, 73, 73],
    [40, 40, 40],
    [24, 24, 24],
    [0, 0, 0],
    [0, 0, 0],
    [0, 130, 0],
    [0, 56, 0],
    [154, 138, 0],
    [121, 89, 0],
    [73, 40, 0],
    [154, 8, 0],
    [105, 0, 0],
    [56, 0, 0],
    [0, 0, 0],
    [154, 154, 154],
    [0, 0, 0],
    [231, 231, 231],
    [203, 203, 203],
    [178, 178, 178],
    [154, 154, 154],
    [130, 130, 130],
    [105, 105, 105],
    [77, 77, 77],
    [52, 52, 52],
    [223, 195, 178],
    [203, 166, 150],
    [182, 142, 125],
    [162, 117, 105],
    [138, 93, 85],
    [121, 73, 69],
    [97, 52, 52],
    [93, 36, 36],
    [134, 52, 44],
    [178, 69, 52],
    [223, 89, 52],
    [170, 178, 113],
    [130, 150, 81],
    [93, 121, 56],
    [60, 93, 36],
    [32, 65, 20],
    [203, 150, 12],
    [166, 121, 8],
    [130, 93, 8],
    [16, 60, 97],
    [20, 81, 125],
    [20, 105, 154],
    [24, 125, 182],
    [0, 0, 0],
    [20, 52, 162],
    [24, 65, 203],
    [255, 0, 255],
    [255, 0, 255],
    [182, 182, 227],
    [166, 166, 219],
    [154, 154, 211],
    [142, 142, 203],
    [134, 130, 199],
    [125, 121, 190],
    [113, 109, 182],
    [105, 101, 178],
    [101, 89, 170],
    [89, 81, 162],
    [85, 73, 158],
    [77, 65, 150],
    [69, 56, 138],
    [65, 48, 130],
    [56, 44, 121],
    [56, 36, 109],
    [48, 32, 101],
    [44, 24, 89],
    [255, 0, 255],
    [255, 0, 255],
    [255, 0, 255],
    [255, 0, 255],
    [255, 0, 255],
    [211, 195, 235],
    [243, 219, 243],
    [255, 243, 243],
    [255, 255, 255],
    [0, 65, 0],
    [0, 65, 16],
    [0, 65, 32],
    [0, 65, 48],
    [0, 65, 65],
    [0, 48, 65],
    [0, 32, 65],
    [0, 16, 65],
    [195, 0, 0],
    [195, 195, 0],
    [0, 0, 195],
    [56, 32, 65],
    [65, 32, 65],
    [65, 32, 56],
    [65, 32, 48],
    [65, 32, 40],
    [65, 32, 32],
    [65, 40, 32],
    [65, 48, 32],
    [65, 56, 32],
    [65, 65, 32],
    [56, 65, 32],
    [48, 65, 32],
    [40, 65, 32],
    [0, 0, 0],
    [227, 195, 162],
    [227, 195, 65],
    [195, 162, 48],
    [178, 146, 32],
    [162, 130, 16],
    [97, 81, 0],
    [44, 101, 48],
    [0, 0, 0],
    [227, 227, 227],
    [211, 211, 211],
    [195, 195, 195],
    [178, 178, 178],
    [162, 162, 162],
    [146, 146, 146],
    [130, 130, 130],
    [113, 113, 113],
    [97, 97, 97],
    [81, 81, 81],
    [65, 65, 65],
    [48, 48, 48],
    [32, 32, 32],
    [16, 16, 16],
    [0, 0, 0],
    [0, 243, 32],
    [243, 195, 162],
    [243, 178, 162],
    [178, 113, 97],
    [146, 81, 65],
    [113, 65, 48],
    [81, 32, 32],
    [48, 16, 16],
    [48, 32, 0],
    [178, 0, 0],
    [65, 81, 243],
    [0, 32, 227],
    [0, 32, 211],
    [0, 0, 97],
    [243, 243, 0],
    [243, 243, 243]
  ].map{|arr| Palette.new(*arr)}
=begin
    Array.new(0x60){|i| Palette.new( 8*i, 2*i, 2*i) }.concat(
      [[  0,  0,  0], [ 63,  0, 63], [ 45, 35, 31], [ 42, 32, 29], # 00-03
       [ 40, 29, 26], [ 38, 27, 24], [ 35, 24, 22], [ 33, 22, 20], # 04-07
       [ 31, 19, 18], [ 28, 17, 16], [ 26, 15, 14], [ 24, 13, 13], # 08-0B
       [  4, 32,  0], [  3, 30,  0], [  2, 28,  0], [  1, 26,  0], # 0C-0F
       [  1, 24,  0], [  1, 22,  0], [  0, 20,  0], [  0, 18,  0], # 10-13
       [  0, 17,  0], [  0, 15,  0], [ 10, 26, 29], [  8, 24, 28], # 14-17
       [  7, 21, 26], [  5, 19, 25], [  4, 17, 24], [  3, 14, 23], # 18-1B
       [  1, 12, 22], [  1, 10, 21], [  0,  8, 20], [  0,  6, 19], # 1C-1F
       [  0,  0,  0], [ 57, 57, 57], [ 50, 50, 50], [ 44, 44, 44], # 20-23
       [ 38, 38, 38], [ 32, 32, 32], [ 26, 26, 26], [ 19, 19, 19], # 24-27
       [ 13, 13, 13], [ 55, 48, 44], [ 50, 41, 37], [ 45, 35, 31], # 28-2B
       [ 40, 29, 26], [ 34, 23, 21], [ 30, 18, 17], [ 24, 13, 13], # 2C-2F
       [ 23,  9,  9], [ 33, 13, 11], [ 44, 17, 13], [ 55, 22, 13], # 30-33
       [ 42, 44, 28], [ 32, 37, 20], [ 23, 30, 14], [ 15, 23,  9], # 34-37
       [  8, 16,  5], [ 50, 37,  3], [ 41, 30,  2], [ 32, 23,  2], # 38-3B
       [  4, 15, 24], [  5, 20, 31], [  5, 26, 38], [  6, 31, 45], # 3C-3F
       [  0,  0,  0], [  5, 13, 40], [  6, 16, 50], [ 63,  0, 63], # 40-43
       [ 63,  0, 63], [ 45, 45, 56], [ 41, 41, 54], [ 38, 38, 52], # 44-47
       [ 35, 35, 50], [ 33, 32, 49], [ 31, 30, 47], [ 28, 27, 45], # 48-4B
       [ 26, 25, 44], [ 25, 22, 42], [ 22, 20, 40], [ 21, 18, 39], # 4C-4F
       [ 19, 16, 37], [ 17, 14, 34], [ 16, 12, 32], [ 14, 11, 30], # 50-53
       [ 14,  9, 27], [ 12,  8, 25], [ 11,  6, 22], [ 63,  0, 63], # 54-57
       [ 63,  0, 63], [ 63,  0, 63], [ 63,  0, 63], [ 63,  0, 63], # 58-5B
       [ 52, 48, 58], [ 60, 54, 60], [ 63, 60, 60], [ 63, 63, 63]  # 5C-5F
      ].map{|arr| Palette.new(arr[0] << 2, arr[1] << 2, arr[2] << 2)})
        .concat Array.new(0x40){|i| Palette.new( 0, 2*i, i) }
=end
end
