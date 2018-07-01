# coding: utf-8
require './images.rb'
require './compression.rb'


COMPRESSIONS = {:raw => 0, :rle1 => 1, :rle2 => 2, :pp => 50 }

class ACE < ImageGroup
  attr_accessor :anim_speed # TODO: factor out into ImageGroup

  def compression_mode(subformat)
    # mode 0: no compression
    # mode 1: RLE (Variante 1/NVF: 0x7F als RLE-Marker)
    # mode 2: RLE (Variante 2/TGA: Werte > 0x80 als RLE-Marker & Lauflänge)
    # mode 50: Amiga PowerPack 2.0
    case subformat
    when 0; :raw
    when 1; :rle1
    when 2; :rle2
    when 50; :pp
    else raise("unknown ACE mode #{subformat}")
    end
  end

  def read(filename)
    file = File.open(filename, IO::BINARY)
    magic   = file.read(4).unpack("a*")[0]
    raise "Error: invalid ACE format identifier '#{magic}'" if magic != "ACE\x00"
    version = file.read16
    part_count = file.read08
    @anim_speed = file.read08
    imglist_offset = []

    if part_count == 1
      @parts << ImageList.new
      @parts.last.dimensions = Rectangle.new(0,0, file.read16, file.read16)
      @parts.last.images = Array.new( file.read08 )
      @parts.last.play_mode = file.read08
      @parts.last.palette = @palette
    else
      for i in 0...part_count
        @parts << part = ImageList.new
        imglist_offset << file.read32

        part.name = file.read16.to_s
        part.dimensions.width  = file.read16
        part.dimensions.height = file.read16
        part.dimensions.x0     = file.readS16 # TODO: is signed correct here?
        part.dimensions.y0     = file.readS16
        part.images = Array.new( file.read08 ){ Image.new }
        part.playmode = file.read08 # TODO: Abspielmodus
        part.palette = @palette
        puts "part #{part.name} dims: #{@parts.last.dimensions}"
      end
    end

    for i in 0...part_count
      imglist_data_size = ( ( i < part_count-1 ) ? imglist_offset[i+1] : (file.size - 256*3)  -  imglist_offset[i]  )
      #raise "Error: broken file offset: #{imglist_offset[i]} is not #{file.tell}" if file.tell != imglist_offset[i]
      #file.seek(imglist_offset[i]) # TODO: this is probably wrong
      for img in @parts[i].images
        compressed_size = file.read32
        dims = file.read(8).unpack("SSSS")
        img.dimensions = Rect.new( dims[0], dims[1], dims[3], dims[2] ) # width/height in swapped order
        subformat = file.read08
        file.read08 # TODO: add action-button to image
        img.compressed_data = file.read(compressed_size).unpack("C*")
        img.data = decompress( img.compressed_data, compression_mode(subformat) )
        img.palette = @palette
      end
    end

    raise "Error: palette size invalid: #{file.size - file.tell} bytes before end, should be 768" if file.size-file.tell != 3*256

    # Palette
    256.times do
      rgb = file.read(3).unpack("CCC")
      @palette << Palette.new(rgb[0], rgb[1], rgb[2])
    end

    # Infer global dimensions from local parts
    global_w, global_h = @parts.inject([0,0]){|acc, part|
      acc = [
        [acc[0], part.dimensions.width].max,
        [acc[1], part.dimensions.height].max
      ]}
    @dimensions = Rect.new(0,0, global_w, global_h)
    file.close
  end

  def write(filename)
    # compress all the images (needs to be done before writing headers so we know the sizes / offsets
    for part in @parts do
      for image in part.images do
        image.compressed_data = compress(image.data, :raw) # TODO: support other subformats
      end
    end

    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write("ACE\0") # magic number
    file.write16 0x0001 # version number
    file.write08 @parts.size
    file.write08 @anim_speed # TODO

    # Animation sequences
    if @parts.size == 1
      part = @parts[0]
      file.write16 part.dimensions.width
      file.write16 part.dimensions.height
      file.write08 part.images.size
      file.write08 0 # TODO: Abspielmodus
    else
      aniheader_ofs = file.tell + @parts.size * (4 + 2 + 4*2 + 1 + 1)
      for part in @parts do
        puts "part #{part.name} dims: #{@parts.last.dimensions}"
        file.write32 aniheader_ofs # offset of first img
        file.write16 part.name.to_i # id number
        file.write16 part.dimensions.width
        file.write16 part.dimensions.height
        file.write16 part.dimensions.x0
        file.write16 part.dimensions.y0
        file.write08 part.images.size
        file.write08 0 # TODO: Abspielmodus
        aniheader_ofs += part.images.inject(0){ |sum, img| sum += img.compressed_data.size }
      end
    end

    # write all the single images
    for part in @parts do
      for image in part.images do
        file.write32 image.compressed_data.size # +4=4
        file.write16 image.dimensions.x0        # +2=6
        file.write16 image.dimensions.y0        # +2=8
        file.write16 image.dimensions.height    # +2=10
        file.write16 image.dimensions.width     # +2=12
        file.write08 image.subformat            # +1=13
        file.write08 0 # TODO: Action-Button    # +1=14
        file.write image.compressed_data.pack("C*")        # +0=14
      end
    end

    for pal in @palette do
      file.write( [ pal.r, pal.g, pal.b ].pack("CCC") )
    end
    file.close
  end
end
