# coding: utf-8
def decompress( compressed, compression_mode )
  case compression_mode
  when :raw  then return compressed
  when :pp   then return decompress_pp(   compressed )
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

class ReverseBitReaderA
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
    return 0 if eof?
    ##raise "Error: End of bitstream reached" if eof?
    out = 0
    for i in 0...num do
      if @bitpos == 0
        @offset -= 1
        @bitpos = 8
        @current_byte = @data[@offset]
      end
      @bitpos -= 1
      out = out << 1 | ((@current_byte >> @bitpos) & 0x01)
    end
    return out
  end
  def eof?
    @offset <= 0 && @bitpos == 0
  end
end

class ReverseBitReaderB
  def initialize(data)
    @data    = data
    raise "Error: wrong input (should be byte array)" if not (data.class == Array && data.first.class == Fixnum)
    @offset  = @data.size-1
    @bitpos  = 0
    @current_byte = @data[@offset]
  end
  def read1
    read(1)
  end
  def read(num)
    return 0 if eof?
    ##raise "Error: End of bitstream reached" if eof?
    out = 0
    for i in 0...num do
      if @bitpos == 8
        @offset -= 1
        @bitpos = 0
        @current_byte = @data[@offset]
      end
      out = out << 1 | ((@current_byte >> @bitpos) & 0x01)
      @bitpos += 1
    end
    return out
  end
  def eof?
    @offset <= 0 && @bitpos == 8
  end
end

def decompress_pp(data)
  out = []
  packed_size = data.size
  m_packed_size = data.shift(4).pack("C4").unpack("L<")[0]  # first 4 bytes are runlength # TODO: its not that simple, cf. g105de_seg004.cpp in BrightEyes
  offset_lens = data.shift(4) # next 4 bytes are offset lenses

  # Get skip bits and unpacked size; sanity checks
  skip_bits = data.pop
  ##m_unpacked_size = data.pop(5).pack("C5").unpack("L>C")[0] & 0x00FFFFFF # TODO!! ¿NVF?
  m_unpacked_size = ("\x00"+data.pop(3).pack("C3")).unpack("L>")[0] & 0x00FFFFFF # TODO!! ¿ACE?
  raise "Error: Powerpack packed length mismatch: should be #{packed_size}, is #{m_packed_size}" if packed_size != m_packed_size
  raise "Error: Powerpack packed size (#{packed_size}) >= unpacked size (#{m_unpacked_size})" if packed_size >= m_unpacked_size
  bits = ReverseBitReaderB.new(data)
  skipped = bits.read(skip_bits)
  ##puts "skipped #{skip_bits} bits: %0#{skip_bits}b" % skipped
  ##puts "offset lenses are #{offset_lens}; skipping #{skip_bits} bits. Depacking from #{m_packed_size} to #{m_unpacked_size} bytes"

  while not bits.eof? do
    if bits.read1 == 0 # literal sequence
      len = 1
      begin b = bits.read(2); len+= b; end until b < 3 # read length of sequence
      ##puts "reading #{len} literal bytes"
      len.times { out << bits.read(8) }
      break if bits.eof?
    end
    # Pattern mode: read runlength / offset lens
    x = bits.read(2)
    offs_bitlen = offset_lens[x]
    ##puts "offset lens ##{x}: #{offs_bitlen} bits"
    runlength = x+2
    if x==3
      x = bits.read1
      offs_bitlen = 7 if x==0
      offset=bits.read(offs_bitlen)
      ##puts "runlength lens is #{offs_bitlen} bits and offset is #{offset}"
      loop do
        x=bits.read(3)
        runlength += x
        break if x!=7
      end
    else
      offset=bits.read(offs_bitlen)
    end
    ##puts "reading #{runlength} bytes from reloffset -#{offset}"
    raise "ERROR: invalid offset while reading PP data" if out.size<offset
    runlength.times{
      w = out[out.size-offset-1]
      out << w
    }
  end
  return out.reverse
end

def compress_pp(data) # TODO

  raise "PowerPack compression not supported yet"
end
