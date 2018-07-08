# coding: utf-8
require './images.rb'
require './compression.rb'


class AIF < ImageHandler
  def compression_mode(aif)
    # mode 0: no compression
    # mode 1: RLE (Variante 1/NVF: 0x7F als RLE-Marker)
    # mode 2: RLE (Variante 2/TGA: Werte > 0x80 als RLE-Marker & Lauflänge)
    # mode 50: Amiga PowerPack 2.0
    case aif.subformat
    when 0; :raw
    when 2; :unknown_aif_0x02
    when 3; :pp
    else raise("unknown AIF mode #{aif.subformat}")
    end
  end

  def read(filename)
    aif   = Image.new
    file  = File.open(filename, IO::BINARY)

    magic        = file.read(3).unpack("a*")[0]
    raise "Error: invalid AIF format identifier '#{magic}'" if magic != "AIF"
    unknown1     = file.read08 # TODO: version?
    aif.subformat   = file.read08
    unknown2     = file.read08
    aif.dimensions  = Rect.new(0,0, file.read16, file.read16)
    palette_size = file.read16
    unknown3     = file.read(18)

    # pixel data
    if compression_mode(aif) == :raw
      aif.compressed_data = file.read(aif.dimensions.size).unpack("C*")
    elsif compression_mode(aif) == :pp
      comp_size = file.read32
      aif.compressed_data = file.read(comp_size).unpack("C*")
      uncomp_size = file.read32
      raise "Error: decompressed data size mismatch: should be #{aif.dimensions.size}, but file says #{uncomp_size}" if aif.dimensions.size != uncomp_size
    else
      # TODO: unknown format
      raise "Error: AIF subformat 0x02 not yet supported"
    end
    aif.data = decompress(aif.compressed_data, compression_mode(aif))

    # Palette
    palette_size.times do
      rgb = file.read(3).unpack("CCC")
      aif.palette << Palette.new(rgb[0], rgb[1], rgb[2])
    end

    file.close
    return aif
  end

  def write(filename, aif)
    file = File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.write   "AIF"
    file.write08 0x00 # unknown1
    file.write08 aif.subformat
    file.write08 0x00 # unknown2
    file.write16 aif.dimensions.width
    file.write16 aif.dimensions.height
    file.write16 aif.palette.size
    file.write(Array.new(18, 0x00).pack("C*")) # unknown3

    aif.compressed_data = compress(aif.data, compression_mode(aif))
    # pixel data
    if compression_mode(aif) == :raw
      file.write(aif.compressed_data.pack("C*"))
    elsif compression_mode(aif) == :pp
      file.write32 aif.compressed_data.size
      file.write(aif.compressed_data.pack("C*"))
      file.write32 aif.data.size
    else
      # TODO: unknown format
      raise "Error: AIF subformat 0x02 not yet supported"
    end

    # Palette
    for pal in aif.palette do
      file.write( [ pal.r, pal.g, pal.b ].pack("CCC") )
    end
    file.close
  end
end
