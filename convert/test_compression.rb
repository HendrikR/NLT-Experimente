require 'test/unit'
require './compression.rb'
require './test_images.rb' # for generating random pixels


class TestCompression < Test::Unit::TestCase
  def test_bitreaderA
    data_in = Array.new(16){|i| 11*i}
    data_in += [0x00, 0xFF, 0x11, 0x77]
    bits = ReverseBitReaderA.new(data_in)
    data_out = []
    (data_in.size).times{
      data_out << bits.read(8)
    }
    assert_equal( data_in.reverse, data_out )
  end

  def test_bitreaderB
    data_in = Array.new(16){|i| 11*i}
    data_in += [0x00, 0xFF, 0x11, 0x77]
    bits = ReverseBitReaderB.new(data_in)
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

  # r
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

