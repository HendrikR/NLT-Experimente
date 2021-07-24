require 'test/unit'
require './compression.rb'
require './test_images.rb' # for generating random pixels


class TestCompression < Test::Unit::TestCase
  # swaps the bits within an 8-bit number @b.
  def swap_bits(b)
    (((b >> 7) & 0x01) << 0) |
      (((b >> 6) & 0x01) << 1) |
      (((b >> 5) & 0x01) << 2) |
      (((b >> 4) & 0x01) << 3) |
      (((b >> 3) & 0x01) << 4) |
      (((b >> 2) & 0x01) << 5) |
      (((b >> 1) & 0x01) << 6) |
      (((b >> 0) & 0x01) << 7)
  end

  def bit_test_data
    data_in  = Array.new(8){ rand 256 }
    data_in += Array.new(4){|i| 37*i}
    data_in += [0x00, 0xFF, 0x11, 0x77]
    return data_in
  end
    
  
  def test_bitreader_bytewise
    data_in = bit_test_data()
    bits = ReverseBitReader.new(data_in)
    data_out = []
    data_in.size.times{
      data_out << swap_bits(bits.read(8))
    }
    assert_equal( data_in.reverse, data_out )
  end

  def test_bitreader_bitbyte
    data_in = bit_test_data()
    data_out_bits  = Array.new
    data_out_bytes = Array.new
    bits = ReverseBitReader.new(data_in)
    data_in.size.times{
      byte_out = 0
      8.times{ byte_out = (byte_out << 1) | (bits.read1 & 1) }
      data_out_bits << swap_bits(byte_out)
    }
    bits.reset!
    data_in.size.times{
      data_out_bytes << swap_bits(bits.read(8))
    }
    assert_equal( data_out_bits, data_out_bytes )
  end

  def test_bitwriter_bytewise
    data_in = bit_test_data()
    bits = ReverseBitWriter.new
    data_in.size.times{|i| bits.write(8, swap_bits(data_in[i])) }

    data_out = bits.stream()
    assert_equal( 0, bits.bitpos % 8 )
    assert_equal( data_in.size, data_out.size )
    assert_equal( data_in.reverse, data_out )
  end
  
  def test_bitwriter_bitbyte
    # Test if bitwriter writes the same data with 1-bit and 8-bit #write calls
    data_in = bit_test_data()

    bits = ReverseBitWriter.new
    data_in.size.times{|i| bits.write(8, swap_bits(data_in[i])) }
    data_out_bytes = bits.stream()

    bits.reset!
    data_in.size.times{|i|
      byte_in  = data_in[i]
      8.times{ bits.write(1, byte_in & 1); byte_in >>= 1 }
    }

    data_out_bits = bits.stream()
    assert_equal( data_out_bytes, data_out_bits )
  end

  def test_bitwriter_byte_arr
    # Test if bitwriter writes the same data with #write and #writeArr
    data_in = bit_test_data()

    bits = ReverseBitWriter.new
    data_in.size.times{|i| bits.write(8, swap_bits(data_in[i])) }
    data_out_bytes = bits.stream()

    bits.reset!
    data_in.size.times{|i|
      arr = []
      byte_in  = data_in[i]
      8.times{ arr << (byte_in & 1); byte_in >>=1 }
      bits.writeArr(arr)
    }

    data_out_arr = bits.stream()
    assert_equal( data_out_bytes, data_out_arr )
  end

  def test_bit_readwrite
    # some more bits to test uneven boundaries
    stray_bits = [5, 0b01101]
    data_in = bit_test_data()
    bit_wr = ReverseBitWriter.new
    data_in.size.times{|i| bit_wr.write(8, data_in[i]) }
    bit_wr.write(stray_bits[0], stray_bits[1]) # write stray bits

    bit_rd = ReverseBitReader.new( bit_wr.stream() )
    data_out = Array.new(data_in.size){ bit_rd.read(8) }
    data_out << bit_rd.read(stray_bits[0]) # don't forget to read stray bits

    data_in << stray_bits[1]  # add stray bits to data_in (as a final byte)

    assert_equal( data_in.size, data_out.size )
    assert_equal( data_in, data_out )
  end
  
  def recompression_test(format)
    #data_ein = generate_rle_pixels(30+rand(10), 30+rand(10)) # generate some amount of rle-friendly data
    data_ein = generate_rle_pixels(4,3)
    data_cmp = compress(data_ein, format)    # compress it
    data_out = decompress(data_cmp, format)  # decompress again
    assert_equal( data_ein, data_out )       # result should be same as input
    #assert( data_cmp.size <= data_ein.size ) # compressed data should not be larger
  end

  def ntest_recompression_uli
    recompression_test(:uli)
  end

  def tnest_recompression_rle1
    recompression_test(:rle1)
  end

  def tenst_recompression_rle2
    recompression_test(:rle2)
  end

  def test_recompression_pp
    recompression_test(:pp)
  end
end

