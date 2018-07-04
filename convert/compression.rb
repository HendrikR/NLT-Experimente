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
    if c == last_byte && seq_len < 255
      seq_len += 1
    else
      if seq_len < 3 && last_byte != 0x7F
        seq_len.times{ out << last_byte }
      else
        out << 0x7F << seq_len << last_byte
      end
      last_byte = c
      seq_len = 1
    end
  end
  # don't forget the last sequence
  if seq_len < 3 && c != 0x7F
    seq_len.times{ out << last_byte }
  else
    out << 0x7F << seq_len << last_byte
  end

  return out
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

class ReverseBitReader
  def initialize(data)
    @data    = data
    raise "Error: wrong input (should be byte array)" if not (data.class == Array && data.first.class == Fixnum)
    @offset  = @data.size-1
    @bitpos  = 8
    @current_byte = @data[@offset]
  end
  def read1
    read(1)
  end
  def read(num)
    raise "Error: End of bitstream reached" if eof?
    out = 0
    for i in 0...num do
      if @bitpos == 0
        @offset -= 1
        @bitpos = 8
        @current_byte = @data[@offset]
      end
      @bitpos -= 1
      #out = out << 1 | (@current_byte & 0x01)
      #@current_byte >>= 1 # TODO: this code is wrong, but corrected, it might be faster. or not?
      out = out << 1 | ((@current_byte >> @bitpos) & 0x01)
    end
    return out
  end

  def eof?
    @offset <= 0 && @bitpos == 0
  end
end

def decompress_pp(data) # TODO
  out = []
  bits = ReverseBitReader.new(data)
  bits.read(4*8) # skip first 4 bytes # TODO: its not that simple, cf. g105de_seg004.cpp in BrightEyes
  offset_lens = Array.new(4) { bits.read(8) }

  while not bits.eof? do
    if bits.read1 == 0 # literal sequence
      len = 0
      begin b = bits.read(2); len+= b; end until b < 3 # read length of sequence
      puts "pp writing #{len} literal bytes"
      len.times { out << bits.read(8) }
      break if bits.eof?
    end
    # TODO/PEND: the interesting part of PP
    x = bits.read(2)
    offs_bitlen = offset_lens[x]
    puts "offset lens ##{x}: #{offs_bitlen} bits"
    todo = x+2
    if x==3
      # TODO: While this might be part of PP, the NLT does not use this fancy variable offset lens I think.
      x = bits.read1
      offs_bitlen = 7 if x==0
      offset=bits.read(offs_bitlen) # TODO: brighteyes has some really weird logic here. seems offset_lens[1] is actually "read the offs_bitlen from the stream"
      puts "strangecase says lens is #{offs_bitlen} bits and offset is #{offset}"
      while x==7 do
        x=bits.read(3)
        todo += x
      end
    else
      offset=bits.read(offs_bitlen)
    end
    puts "reading #{todo} bytes from #{offset} bytes far away"
    todo.times{ out << out[out.size-offset] }
  end
  return out
  raise "PowerPack decompression not supported yet"
end

def compress_pp(data) # TODO

  raise "PowerPack compression not supported yet"
end





