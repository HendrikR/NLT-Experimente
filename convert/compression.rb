# coding: utf-8

# TODO: careful optimization can yield great performance improvements here.

def decompress( compressed, compression_mode )
  case compression_mode
  when :raw  then return compressed
  when :pp   then return decompress_pp(   compressed )
  when :rle1 then return decompress_rle1( compressed )
  when :rle2 then return decompress_rle2( compressed )
  when :rle3 then return decompress_rle3( compressed )
  when :uli  then return decompress_uli(  compressed )
  else raise("unknown compression mode #{compression_mode}")
  end
end

def compress( decompressed, compression_mode )
  case compression_mode
  when :raw  then return decompressed
  when :pp   then return compress_pp(   decompressed )
  when :rle1 then return compress_rle1( decompressed )
  when :rle2 then return compress_rle2( decompressed )
  when :rle3 then return compress_rle3( decompressed )
  when :uli  then return compress_uli(  decompressed )
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


def decompress_rle3(data)
  # RLE (Variant 3/AIF: value > 0x7F: rle length; < 0x80: raw byte length)
  out = []
  i = 0
  while i < data.size
    block_len = (data[i] & 0x80 == 0)  ?  data[i] + 1  :  257-data[i]
    if data[i] < 0x80 # < 0x80: raw block of *block_len* pixels
      block_len.times{  out << data[i += 1]  }
    else # >= 0x80 -- repeat next pixel (
      val = data[i += 1]
      block_len.times{  out << val  }
    end
    i += 1
  end
  return out
end

def compress_rle3(data)
  raise "not supported yet"
end

class ReverseBitReader
  def initialize(data)
    @data    = data
    raise "Error: wrong input (should be byte array)" if not (data.class == Array && data.first.class == Integer)
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

class ReverseBitWriter
  attr_reader :bitpos

  def initialize
    @data    = []
    @bitpos  = 8
    @current_byte = 0
  end

  def write0; write(1, 0); end
  def write1; write(1, 1); end
  def write8(bits); write(8, bits); end
  def writeSeq(*arr); writeArr(arr); end

  # TODO: Bad performance. Shifts bits around twice, is this necessary?
  def write(num, dat)
    bitarr = []
    for i in 0...num do
      bitarr << (dat & 0b1)
      dat >>= 1
    end
    writeArr(bitarr)
  end
  
  def writeArr(bits)
    num = bits.size
    for b in bits do
      if @bitpos == 8
        @bitpos = 0
        @data.unshift(0) # shift in a new, emtpy byte
      end
      @data[0] |= (b & 0b1) << @bitpos
      @bitpos += 1
    end
  end
  
  def getStream; @data; end
  def bytes; @data.size; end
end

def decompress_pp(data)
  out = []
  # PP starts with 4 bytes packed size, ends with 3 bytes (bigendian) unpacked size
  packed_size = data.size - 3
  m_packed_size = arr_read32(data.shift(4))  # first 4 bytes are runlength # TODO: its not that simple, cf. g105de_seg004.cpp in BrightEyes
  offset_lens = data.shift(4) # next 4 bytes are offset lenses

  # Get skip bits and unpacked size; sanity checks
  skip_bits = data.pop
  m_unpacked_size = arr_read24be(data.pop(3)) # TODO!! ¿ACE?


  if packed_size-4 != m_packed_size && packed_size-5 != m_packed_size
    # -5 for aif, -4 for everything else
    raise "Error: Powerpack packed length mismatch: should be #{packed_size-4}, is #{m_packed_size}"
  end
  bits = ReverseBitReader.new(data)
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
  # Seems to be necessary, otherwise data is 2 pixels too long and images shifted right by 2 pixels
  2.times{ out.pop }
  return out.reverse
end

def compress_pp_proper(data)
  # TODO/PEND
  out = []
  bits = ReverseBitWriter.new
  # TODO: Lenses as seen in sample pictures. Check if another pattern is better.
  offset_lens = [9,10,10,10]

  # build byte index
  byte_index = Hash.new([])
  data.each_with_index{|v, i| byte_index[v] << i}

  # 3 pointers / indices:
  psrc = 0  # start of pattern to copy from
  ptgt = 0  # start of pattern to copy to
  len = 0
  
  while ptgt < data.size
    # check if pattern continues
    if data[psrc+len] == data[ptgt+len]
      len += 1
    else
      # pattern psrc+len broken, search for a longer one nsrc+nlen
      nsrc = psrc
      nlen = 0
      loop do
        nsrc = byte_index.bsearch{|x| x > nsrc}
        break if nsrc == nil || nsrc >= ptgt
        for i in 0..len do break if data[nsrc+i] != data[ptgt+i]; end
        if i == len && data[nsrc+len] == data[ptgt+len]
          psrc = nsrc
          break
        end
      end
      if nsrc != psrc # didn't find a longer pattern: write this one
        # TODO!!!
        if false && len > 3
          # Pattern long enough for compression -- save compressed
        else
          # Pattern too short for compression -- save uncompressed
          bits.write0 # uncompressed
          (len/3).times{ bits.writeArr[1,1] }
          bits.writeArr[len%3 / 2, len%3 & 1]
          len.times{|i| bits.write(8, data[ptgt+i]) }
        end
      end
    end
  end

  out += arr_write32(bits.byteSize)
  out += offset_lens
  out << skip_bits
  out += arr_write24be(data.size)
  out += bits.getStream
end

def compress_pp(data) # TODO
  compress_pp_proper(data)
  raise "ppo compression not supported yet"
end

def decompress_uli(data)
  i = 0
  out = []
  while i < data.size
    len = data[i]
    i+= 1
    if len < 0x80
      color = data[i]
      len.times{ out << color }
      i += 1
    else
      len -= 0x80
      len.times{
        out << data[i]
        i+= 1
      }
    end
  end
  return out
end

def compress_uli(data) # TODO
  # RLE (Variante 3/ULI: Werte > 0x80 als RLE-Marker & Lauflänge)
  out = []
  # 3 pointers / indices:
  ptr_done = 0 # first byte that is not yet encoded
  ptr_same = 0 # first byte of last sequence of same-valued bytes
  ptr_head = 1 # first byte that is not yet analyzed


  loop do
    # Encode if at end of stream, or unencoded part gets too long
    if (ptr_head == data.size) or (ptr_head - ptr_done >= 0x7F)
      # Encode inhomogenous data as >=0x80 prefix + vector of bytes
      len = ptr_same - ptr_done
      if len > 0
        out << (len + 0x80)
        out.concat( data[ptr_done...ptr_same] )
      end
      # Encode same-valued data as < 0x80 prefix + value
      len = ptr_head - ptr_same
      if len > 0
        out << len
        out << data[ptr_same]
      end
      # set pointers
      ptr_done = ptr_same = ptr_head
    end
    break if ptr_head == data.size
    # prepare for next round: increment pointer(s)
    if data[ptr_same] != data[ptr_head] then ptr_same = ptr_head; end
    ptr_head += 1
  end
  #puts "head at #{ptr_head}, ending compr with #{out}"
  return out
end
