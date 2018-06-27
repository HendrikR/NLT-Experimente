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
    magic   = file.read(4).unpack("a*")
    version = file.read16
    part_count = file.read08
    @anim_speed = file.read08
    imglist_offset = []

    if part_count == 1
      @parts << ImageList.new
      @parts.last.dimensions = Rectangle.new(0,0, file.read16, file.read16)
      @parts.last.images = Array.new( file.read08 )
      @parts.last.play_mode = file.read08
    else
      for i in 0...part_count
        @parts << ImageList.new
        imglist_offset << file.read32

        @parts.last.name = file.read16.to_s
        @parts.last.dimensions.width  = file.read16
        @parts.last.dimensions.height = file.read16
        @parts.last.dimensions.x0     = file.readS16 # TODO: is signed correct here?
        @parts.last.dimensions.y0     = file.readS16
        @parts.last.images = Array.new( file.read08 ){ Image.new }
        @parts.last.playmode = file.read08 # TODO: Abspielmodus
        @parts.last.palette = @palette
      end
    end

    # TODO: Images
    for i in 0...part_count
      #file.seek(imglist_offset[i])
      #imglist_data_size = ( ( i < part_count-1 ) ? imglist_offset[i+1] : (file.size - 256*3)  -  imglist_offset[i]  )
      raise "Error: broken file offset: #{imglist_offset[i]} is not #{file.tell}" if file.tell != imglist_offset[i]
      #file.read( imglist_data_size )
      for img in @parts[i].images
        # TODO: how long do i need to read here for a single image?
        #img.dimensions = @parts[i].dimensions
        #img.palette = @parts[i].palette
        #img.data = Array.new(@parts[i].dimensions.size, 0) #img.compressed_data # TODO
        compressed_size = file.read32
        img.dimensions = Rect.new( file.read16, file.read16, file.read16, file.read16 )
        subformat = file.read08
        file.read08 # TODO: add action-button to image
        img.compressed_data = file.read(compressed_size)
        img.data = decompress( img.compressed_data, compression_mode(subformat) )
      end
    end

    # Palette
    256.times do
      rgb = file.read(3).unpack("CCC")
      @palette << Palette.new(rgb[0], rgb[1], rgb[2])
    end
    puts file.tell

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
    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write("ACE\0") # magic number
    file.write16 0x0001 # version number
    file.write08 @parts.size
    file.write16 @anim_speed # TODO

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
        file.write32 aniheader_ofs # offset of first img
        file.write16 part.name.to_i # id number
        file.write16 part.dimensions.width
        file.write16 part.dimensions.height
        file.write16 part.dimensions.x0
        file.write16 part.dimensions.y0
        file.write08 part.images.size
        file.write08 0 # TODO: Abspielmodus
        part.images.each{ |image| aniheader_ofs += image.compressed_data.size }
      end
    end

    for part in @parts do
      for image in part.images do
        file.write32 image.compressed_data.size
        file.write16 image.dimensions.x0
        file.write16 image.dimensions.y0
        file.write16 image.dimensions.width
        file.write16 image.dimensions.height
        file.write08 @subformat # TODO: undefined/unset var
        file.write08 0 # TODO: Action-Button
        file.write image.compressed_data
      end
    end

    for pal in @palette do
      file.write( [ pal.r, pal.g, pal.b ].pack("CCC") )
    end
    file.close
  end
end
