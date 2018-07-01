# coding: utf-8
def decompress( compressed, compression_mode )
  case compression_mode
  when :raw  then return compressed
  when :pp   then return decompress_pp( compressed )
  when :rle1 then return decompress_rle1( compressed )
  when :rle2 then return decompress_rle2( compressed )
  else raise("unknown compression mode #{compression_mode}")
  end
end

def compress( decompressed, compression_mode )
  case compression_mode
  when :raw  then return decompressed
  when :pp   then return compress_pp( decompressed )
  when :rle1 then return compress_rle1( decompressed )
  when :rle2 then return compress_rle2( decompressed )
  else raise("unknown compression mode #{compression_mode}")
  end
end

def compress_raw(data)
  return data
end

def compress_rle1(data)
  # RLE (Variante 1/NVF: 0x7F als RLE-Marker)
  out = []
  last_byte = data[0]
  seq_len   = 0
  for c in data do
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


def decompress_rle1(data)
  # RLE (Variante 1/NVF: 0x7F als RLE-Marker)
  out = []
  i   = 0
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
  return out
end

def decompress_rle2(data)
  # RLE (Variante 2/TGA: Werte > 0x80 als RLE-Marker & Lauflänge)
  out = []
  i = 0
  while i < data.size
    block_len = (data[i] & 0x7F) + 1 # run length is lower 7 bits plus 1
    if data[i] < 0x80 # raw block of *block_len* pixels
      block_len.times{ i+=1; out << data[i] }
    else # > 0x80 -- repeat next pixel *block_len* times
      i+= 1
      block_len.times{ out << data[i] }
    end
    i += 1
  end
  return out
end

def compress_rle2(data)
  # RLE (Variante 2/TGA: Werte > 0x80 als RLE-Marker & Lauflänge)
  # TODO: stop after out.size >= @dimensions.size?
  out = []
  i = 0
  while i < data.size
    col = data[i]
    seq_len = 1
    while seq_len < 0x80 && i+seq_len < data.size && data[i+seq_len] == col do seq_len+=1; end
    if seq_len > 1
      out << ((seq_len-1) | 0x80)
      out << col
    else # raw pixels
      seq_len = i+0x80 < data.size ? 0x80 : (data.size-i)
      out << seq_len - 1
      seq_len.times { |j| out << data[i+j] }
    end
    i += seq_len
  end
  return out
end

def decompress_pp(data) # TODO
  raise "PowerPack decompression not supported yet"
end

def compress_pp(data) # TODO
  raise "PowerPack compression not supported yet"
end


