# coding: utf-8
require './images.rb'
require './compression.rb'


class AIF < Image
  def compression_mode
    # mode 0: no compression
    # mode 1: RLE (Variante 1/NVF: 0x7F als RLE-Marker)
    # mode 2: RLE (Variante 2/TGA: Werte > 0x80 als RLE-Marker & Lauflänge)
    # mode 50: Amiga PowerPack 2.0
    case @subformat
    when 0; :raw
    when 2; :unknown_aif_0x02
    when 3; :pp
    else raise("unknown AIF mode #{@subformat}")
    end
  end

  def read(filename)
    file = File.open(filename, IO::BINARY)
    magic        = file.read(3).unpack("a*")[0]
    raise "Error: invalid AIF format identifier '#{magic}'" if magic != "AIF"
    unknown1     = file.read08 # TODO: version?
    @subformat   = file.read08
    unknown2     = file.read08
    @dimensions  = Rect.new(0,0, file.read16, file.read16)
    palette_size = file.read16
    unknown3     = file.read(18)

    # pixel data
    if compression_mode == :raw
      @compressed_data = file.read(@dimensions.size).unpack("C*")
    elsif compression_mode == :pp
      comp_size = file.read32
      @compressed_data = file.read(comp_size).unpack("C*")
      uncomp_size = file.read32
      raise "Error: decompressed data size mismatch: should be #{@dimensions.size}, but file says #{uncomp_size}" if @dimensions.size != uncomp_size
    else
      # TODO: unknown format
      raise "Error: AIF subformat 0x02 not yet supported"
    end
    @data = decompress(@compressed_data, compression_mode)

    # Palette
    palette_size.times do
      rgb = file.read(3).unpack("CCC")
      @palette << Palette.new(rgb[0], rgb[1], rgb[2])
    end
  end

  def write(filename)
    file = File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write   "AIF"
    file.write08 0x00 # unknown1
    file.write08 @subformat
    file.write08 0x00 # unknown2
    file.write16 @dimensions.width
    file.write16 @dimensions.height
    file.write16 @palette.size
    file.write(Array.new(18, 0x00).pack("C*")) # unknown3

    @compressed_data = compress(@data, compression_mode)
    # pixel data
    if compression_mode == :raw
      file.write(@compressed_data.pack("C*"))
    elsif compression_mode == :pp
      file.write32 @compressed_data.size
      file.write(@compressed_data.pack("C*"))
      file.write32 @data.size
    else
      # TODO: unknown format
      raise "Error: AIF subformat 0x02 not yet supported"
    end

    # Palette
    for pal in @palette do
      file.write( [ pal.r, pal.g, pal.b ].pack("CCC") )
    end
    file.close
  end
end
