require 'test/unit'
require './compression.rb'
require './test_images.rb' # for generating random pixels


class TestCompression < Test::Unit::TestCase
  def test_bitreader
    data_in = Array.new(16){|i| 11*i}
    data_in += [0x00, 0xFF, 0x11, 0x77]
    bits = ReverseBitReader.new(data_in)
    data_out = []
    (data_in.size).times{
      b = bits.read(8)
      nbits = (((b >> 7) & 0x01) << 0) |
              (((b >> 6) & 0x01) << 1) |
              (((b >> 5) & 0x01) << 2) |
              (((b >> 4) & 0x01) << 3) |
              (((b >> 3) & 0x01) << 4) |
              (((b >> 2) & 0x01) << 5) |
              (((b >> 1) & 0x01) << 6) |
              (((b >> 0) & 0x01) << 7)
      data_out << nbits
    }
    assert_equal( data_in.reverse, data_out )
  end

  def test_bitwriter
    data_in = Array.new(16){|i| 11*i}
    data_in += [0x00, 0xFF, 0x11, 0x77]
    bits = ReverseBitWriter.new
    data_in.size.times{|i|  bits.write(8, data_in[i])  }
    
    data_out = bits.getStream()
    assert_equal( 0, bits.bitpos % 8 )
    assert_equal( data_in.size, data_out.size )
    assert_equal( data_in.reverse, data_out )
  end

  def notest_bit_readwrite
    # TODO: enable once bitwriter works
    num_bytes = 100
    
    data_in = Array.new(num_bytes){ rand 256 }

    bit_rd = ReverseBitReader.new(data_in)
    bit_wr = ReverseBitWriter.new

    num_bytes.times{|i| bit_wr.write8(data_in[i]) }
    data_out = Array.new(num_bytes){ bit_rd.read(8) }
    assert_equal( data_in.size, data_out.size )
    assert_equal( data_in, data_out )
  end
  
  def recompression_test(format)
    data_ein = generate_rle_pixels(100+rand(100), 100+rand(100)) # generate some amount of rle-friendly data
    data_cmp = compress(data_ein, format)    # compress it
    data_out = decompress(data_cmp, format)  # decompress again

    assert( data_cmp.size <= data_ein.size ) # result should be same as input
    assert_equal( data_ein, data_out )       # compressed data should not be larger
  end

  def test_recompression_uli
    recompression_test(:uli)
  end

  def test_recompression_rle1
    recompression_test(:rle1)
  end

  def test_recompression_rle2
    recompression_test(:rle2)
  end

  def notest_recompression_pp # todo
    recompression_test(:p)
  end
end

