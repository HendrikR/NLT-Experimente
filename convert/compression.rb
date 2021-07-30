# coding: utf-8

# TODO: careful optimization can yield great performance improvements here.

def arr_write32(v);  [v].pack("L<").unpack ("C4"); end
def arr_read32(arr); arr.pack("C4").unpack("L<")[0]; end
def arr_write24be(v);  [v].pack("L>").unpack("C4")[1..3]; end
def arr_read24be(arr); ("\x00"+arr.pack("C3")).unpack("L>")[0]; end

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
  """Read bits in reverse order, lowest bit first.
  Caveat: The bits within a byte are _not_ reversed."""
  def initialize(data)
    @data    = data
    raise "Error: wrong input (should be byte array)" if not (data.class == Array && data.first.class == Integer)
    reset!
  end
  def read1
    read(1)
  end
  def read(num)
    return 0 if eof?
    ##raise "Error: End of bitstream reached" if eof?
    out = 0
    for i in 0...num do
      if @bitpos < 0
        @offset -= 1
        @bitpos = 7
        @current_byte = @data[@offset]
      end
      the_bit = ((@current_byte >> (7-@bitpos)) & 0x01)
      ##puts "state: #{@bitpos}, #{@offset}, #{@current_byte.to_s(16)} --> #{the_bit}"
      out = (out << 1) | ((@current_byte >> (7-@bitpos)) & 0x01)
      @bitpos -= 1
    end
    ##puts "reading #{num} bits: %0#{num}b" % out
    return out
  end
  def eof?
    @offset < 0
  end
  def reset!()
    @offset  = @data.size-1
    @bitpos  = 7
    @current_byte = @data[@offset]
  end
  def pos_str
    "ofs #{@offset}.#{@bitpos}"
  end
end

class ReverseBitWriter
  attr_reader :bitpos

  def initialize
    reset!
  end

  def reset!
    @data    = [0]
    @bitpos  = 0
    @current_byte = 0
  end

  def write8(bits); write(8, bits); end
  def writeSeq(*arr); writeArr(arr); end

  def write(num, bitmask)
    for i in 0...num do
      if @bitpos > 7
        @bitpos = 0
        @data.unshift(0x00) # shift in a new, emtpy byte
      end
      @data[0] = (@data[0] << 1) | (bitmask & 0x01)
      bitmask >>= 1
      @bitpos += 1
    end
  end

  def writeArr(bits)
    num = bits.size
    for b in bits do
      if @bitpos > 7
        @bitpos = 0
        @data.unshift(0x00) # shift in a new, emtpy byte
      end
      @data[0] |= (b & 0b1) << (7 - @bitpos)
      @bitpos += 1
    end
  end
  
  def stream; @data; end
  def byteSize; @data.size; end
  def bitSize; 8*@data.size + @bitpos; end
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

  # TODO: These different sizes are worrysome. Be careful.
  if packed_size+3 != m_packed_size && # ace
     packed_size-5 != m_packed_size && # aif
     packed_size-4 != m_packed_size # nvf
    raise "Error: Powerpack packed length mismatch: should be #{packed_size}/#{packed_size-5}, is #{m_packed_size}"
  end
  bits = ReverseBitReader.new(data)
  skipped = bits.read(skip_bits)
  ##puts "offset lenses are #{offset_lens}; skipping #{skip_bits} bits. Depacking from #{m_packed_size}/#{packed_size} to #{m_unpacked_size} bytes"

  ##puts "skipped bits are: 0b%0#{skip_bits}b" % skipped
  #btr=128; print "reading #{btr} bits: "; while btr>=8 do print " %08b" % bits.read(8); btr-=8; end; puts " %0#{btr}b" % bits.read(btr); exit
  while not bits.eof? do
    if bits.read1 == 0 # literal sequence
      len = 1
      begin b = bits.read(2); len+= b; end until b < 3 # read length of sequence
      len.times { out << bits.read(8) }
      break if bits.eof?
    end
    # Pattern mode: read runlength / offset lens
    x = bits.read(2)
    offs_bitlen = offset_lens[x]
    runlength = x+2
    if x==3
      more = bits.read1
      offs_bitlen = 7 if more==0
      offset=bits.read(offs_bitlen)
      ##puts "runlength is #{runlength} bytes and offset is #{offset}"
      begin rl=bits.read(3); runlength += rl; end while rl==7
    else
      offset=bits.read(offs_bitlen)
    end
    ##puts "offset lens ##{x}: #{offs_bitlen} bits"
    ##puts "reading #{runlength} bytes from reloffset -#{offset} = 0b#{offset.to_s(2)}"
    raise "ERROR: invalid offset while reading PP data, at #{bits.pos_str}" if out.size<offset
    runlength.times{
      w = out[out.size-offset-1]
      out << w
    }
  end
  ##puts "output is #{out.size} bytes long, should be #{m_unpacked_size}"
  return out.reverse
end

def shift_bitarr(arr, bits)
  out = []
  bits = bits % 8
  for i in 1...arr.size do
    out << ( (0xFF & arr[i-1] << bits) | arr[i] >> (8-bits) )
  end
  out << ( 0xFF & (arr.last << bits) )
end

class CompressPP_Raw
  attr_accessor :type, :vals
  def initialize(vals)
    @type = :raw
    @vals = vals
  end
  def length(); @vals.size; end
  def to_s; "RAW: #{@vals}"; end
end

class CompressPP_Ref
  attr_accessor :type, :length, :offset
  def initialize(length, offset)
    @type   = :ref
    @length = length
    @offset = offset
  end
  def getBestLens
    # TODO!!!
  end
  def to_s; "REF: copy #{@length} bytes from ofs -#{@offset}"; end
end

def compress_pp_patternfinder(data)
  pattern_arr = []

  # build byte index
  byte_index = Hash.new
  data.each_with_index{|v, i| byte_index.member?(v)  ?  byte_index[v] << i  :  byte_index[v] = [i] }

  # 3 pointers / indices:
  psrc = 0  # start of pattern to copy from
  ptgt = 0  # start of pattern to copy to
  len = 1
  
  while ptgt+len < data.size
    ##puts "ptgt = #{ptgt}, len=#{len}"
    # check if pattern continues
    if psrc < ptgt && data[psrc+len] == data[ptgt+len] && ptgt + len < data.size-1
      len += 1
    else
      # pattern broken at psrc+len, search for a longer one nsrc+nlen
      ##puts "pattern break at #{ptgt}+#{len}"
      nsrc = psrc
      nlen = 0
      loop do
        nsrc = byte_index[data[ptgt]].bsearch{|x| x > nsrc}
        break if nsrc == nil || nsrc >= ptgt
        for i in 0..len do break if data[nsrc+i] != data[ptgt+i]; end
        if i == len && data[nsrc+len] == data[ptgt+len]
          psrc = nsrc
          break
        end
      end
      if nsrc != psrc # didn't find a longer pattern: write this one
        if len > 2
          # Pattern long enough for compression -- save compressed
          pattern_arr << CompressPP_Ref.new( len, ptgt-psrc )
        else
          pattern_arr << CompressPP_Raw.new( data[ptgt...(ptgt+len)] )
        end
        ptgt += len
        len   = 1
      end
    end
  end

  pattern_arr << CompressPP_Raw.new( [data.last] ) if pattern_arr.last.type == :raw

  return pattern_arr
end

def compress_pp_compactor(patterns)
  compacted = []
  # TODO: Lenses as seen in sample pictures. Check if another pattern is better.
  offset_lens = [9,10,10,10]
  last_type = :ref
  raw_buf = []
  for pattern in patterns do
    if pattern.type == :raw
      if last_type == :raw
        raw_buf.concat( pattern.vals )
      else
        raw_buf = pattern.vals
      end
    elsif pattern.type == :ref
      # TODO: choose best offset lens
      if last_type == :raw
        compacted << CompressPP_Raw.new( raw_buf )
        raw_buf = []
      end
      compacted << CompressPP_Ref.new( pattern.length, pattern.offset )
    else raise "Unknow pattern type '#{pattern.type}'"
    end
    last_type = pattern.type
  end
  compacted << CompressPP_Raw.new( raw_buf ) unless raw_buf.empty?

  return compacted
end

def compress_pp_bitstream(patterns, uncompressed_size)
  out = []
  bits = ReverseBitWriter.new
  last_mode = 0
  offset_lens = [9,10,10,10] ## TODO!! Set and use actual lens, not this bogus thing.
  for pattern in patterns do
    if pattern.type == :raw
      bits.writeSeq(0) # uncompressed
      len = pattern.length - 1
      (len/3).times{ bits.write(2, 0b11) }
      bits.write(2, len % 3)
      puts "writing #{pattern.length} literal bytes"
      pattern.length.times{|i| bits.write(8, pattern.vals[i]) }
      last_mode = 0
    elsif pattern.type == :ref
      bits.writeSeq(1) if last_mode != 0 # compressed
      lens_idx = 3##offset_lens.find_index{|x| Math.log2(ptgt - psrc) <= x }
      puts "using offset lens #{lens_idx}(#{offset_lens[lens_idx]}) because #{Math.log2(pattern.length)}"
      bits.write(2, lens_idx)
      bits.write(1, 1) # following: offset lens & variable runlength (special lens 3:1)
      bits.write(offset_lens[lens_idx], pattern.offset)
      len = pattern.length - (lens_idx+1)
      (len/7).times{ bits.write(3, 0b111)}
      bits.write(3, len % 7)
      last_mode = 1
    else raise "Unknow pattern type '#{pattern.type}'"
    end
  end
  
  # for some reason, we need to add 2 more bytes. meh.
  #if last_mode == 1
    bits.write(1, 0b1) unless last_mode == 0 # may need to add 1-marker for copy
    bits.write(2, 0b00) # lens #0 (2 bytes follow)
    bits.write(offset_lens[0], 1) # distance (-1)
  #end
  
  empty_bits = 8 - bits.bitpos
  out += arr_write32(bits.byteSize + 5)           # compressed size
  out += offset_lens                              # offset lens
  out += shift_bitarr(bits.stream(), empty_bits)  # bitstream
  out += arr_write24be(uncompressed_size)         # uncompressed size
  out << empty_bits                               # skip bits

  print "pp stream: #{bits.stream.size} bytes, #{bits.bitpos} lastbits: "
  bits.stream().each{|x| printf("%08b ", x)}; puts
  print "shifted: "
  shift_bitarr(bits.stream(), empty_bits).each{|x| printf("%08b ", x)}; puts
  puts

  return out
end

def compress_pp(data) # TODO/PEND
  patterns1 = compress_pp_patternfinder(data.reverse)
  patterns2 = compress_pp_compactor(patterns1)
  puts patterns2
  bitstream = compress_pp_bitstream(patterns2, data.size)
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
