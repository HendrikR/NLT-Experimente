# coding: utf-8
require './images.rb'
require './compression.rb'


class ACE < ImageHandler
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
    ace   = ImageGroup.new
    file  = File.open(filename, IO::BINARY)

    magic   = file.read(4).unpack("a*")[0]
    raise "Error: invalid ACE format identifier '#{magic}'" if magic != "ACE\x00"
    version = file.read16
    part_count = file.read08
    ace.anim_speed = file.read08
    imglist_offset = []

    if part_count == 1
      ace.parts << ImageList.new
      ace.parts.last.dimensions = Rect.new(0,0, file.read16, file.read16)
      ace.parts.last.images = Array.new( file.read08 ) { Image.new }
      ace.parts.last.playmode = file.read08
      ace.parts.last.palette = ace.palette
      imglist_offset << file.tell
    else
      for i in 0...part_count
        ace.parts << part = ImageList.new
        imglist_offset << file.read32

        part.name = file.read16.to_s
        part.dimensions.width  = file.read16
        part.dimensions.height = file.read16
        part.dimensions.x0     = file.readS16 # TODO: is signed correct here?
        part.dimensions.y0     = file.readS16
        part.images = Array.new( file.read08 ){ Image.new }
        part.playmode = file.read08 # TODO: Abspielmodus
        part.palette = ace.palette
        ##puts "part #{part.name} dims: #{ace.parts.last.dimensions}, #{part.images.size} pics"
      end
    end

    for i in 0...part_count
      imglist_data_size = ( ( i < part_count-1 ) ? imglist_offset[i+1] : (file.size - 256*3)  -  imglist_offset[i]  )
      #raise "Error: broken file offset: #{imglist_offset[i]} is not #{file.tell}" if file.tell != imglist_offset[i]
      #file.seek(imglist_offset[i]) # TODO: this is probably wrong
      for img in ace.parts[i].images
        compressed_size = file.read32
        #dims = file.read(8).unpack("SSSS")
        #img.dimensions = Rect.new( dims[0], dims[1], dims[3], dims[2] ) # width/height in swapped order. TODO!!: oder nicht?
        img.dimensions = Rect.new( file.read16, file.read16, file.read16, file.read16 )
        img.subformat = file.read08
        file.read08 # TODO: add action-button to image
        img.compressed_data = file.read(compressed_size).unpack("C*")
        img.data = decompress( img.compressed_data, compression_mode(img.subformat) )
        img.palette = ace.palette
      end
    end

    raise "Error: palette size invalid: #{file.size - file.tell} bytes before end, should be 768" if file.size-file.tell != 3*256

    # Palette
    256.times do
      rgb = file.read(3).unpack("CCC")
      ace.palette << Palette.new(rgb[0] << 2, rgb[1] << 2, rgb[2] << 2)
    end

    # Infer global dimensions from local parts
    global_w, global_h = ace.parts.inject([0,0]){|acc, part|
      acc = [
        [acc[0], part.dimensions.width].max,
        [acc[1], part.dimensions.height].max
      ]}
    ace.dimensions = Rect.new(0,0, global_w, global_h)

    file.close
    return ace
  end

  def write(filename, ace)
    # compress all the images (needs to be done before writing headers so we know the sizes / offsets
    for part in ace.parts do
      for image in part.images do
        image.compressed_data = compress(image.data, :raw) # TODO: support other subformats
      end
    end

    file =  File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write("ACE\0") # magic number
    file.write16 0x0001 # version number
    file.write08 ace.parts.size
    file.write08 ace.anim_speed # TODO

    # Animation sequences
    if ace.parts.size == 1
      part = ace.parts[0]
      file.write16 part.dimensions.width
      file.write16 part.dimensions.height
      file.write08 part.images.size
      file.write08 0 # TODO: Abspielmodus
    else
      aniheader_ofs = file.tell + ace.parts.size * (4 + 2 + 4*2 + 1 + 1)
      for part in ace.parts do
        puts "part #{part.name} dims: #{ace.parts.last.dimensions}"
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
    for part in ace.parts do
      for image in part.images do
        file.write32 image.compressed_data.size
        file.write16 image.dimensions.x0
        file.write16 image.dimensions.y0
        file.write16 image.dimensions.width
        file.write16 image.dimensions.height
        file.write08 image.subformat
        file.write08 0 # TODO: Action-Button
        file.write image.compressed_data.pack("C*")
      end
    end

    for pal in ace.palette do
      file.write( [ pal.r >> 2, pal.g >> 2, pal.b >> 2 ].pack("CCC") )
    end
    file.close
  end
end
