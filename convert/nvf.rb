require 'image.rb'

class NVF < ImageList
  attr_accessor :nvf_type

  def uniform_resolution?
    # formats 0, 2, 4 have the same resolution for all subimages.
    # formats 1, 3, 5 have their own resolutions for subimages.
    return @nvf_type % 2 == 0
  end

  def compression_mode
    # modes 0,1: no compression
    # modes 2,3: Amiga PowerPack 2.0
    # modes 4,5: RLE
    case @nvf_type / 2
    when 0; :none
    when 1; :powerpack
    when 2; :rle
    else raise("unknown NVF mode #{@nvf_type}")
    end
  end

  def compress_raw(data)
    return data
  end

  def compress_rle(data)
    # TODO: testinng
    last_byte = data[0]
    seq_len   = 0
    while i < data.size
      c = data[i]
      if c == last_byte
        seq_len += 1
      else
        if seq_len < 2
          seq_len.times{ out << c }
        else
          while seq_len > 0 do
            seq_max = seq_len > 255 ? 255 : seq_len
            out << 0x7F << seq_max << last_byte
            seq_len -= seq_max
          end
        end
        last_byte = c
        seq_len = 1
      end
    end
  end

  def decompress_rle(data)
    out = []
    while i < data.size
      c = data[i]
      if c == 0x7F
        data[i+1].times{ out << data[i+2] }
        i += 3
      else
        out << c
        i += 1
      end
    end
  end

  def decompress_pp(data)
    raise("PowerPack decompression not supported yet")
    # TODO
  end
  def compress_pp(data) # TODO
    raise("PowerPack compression not supported yet")
  end

  def compress(data)
    case compression_mode()
    when :none then compress_raw(data)
    when :powerpack then compress_pp(data)
    when :rle then compress_rle(data)
    else raise("unknown compression #{mode}")
    end
  end

  def write(filename)
    file =  File.open(filename, IO::CREATE | IO::WRONLY | IO::BINARY)
    file.write08 @nvf_type
    file.write08 @images.size

    for img in @images do img.compressed_data = compress(img); end
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
      file.write img.compressed_data
    end
  end

  def read(filename)
  end
end
