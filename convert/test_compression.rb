require 'test/unit'
require './compression.rb'


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
end
# TODO: more tests (compression-decompression equality under random streams for every algorithm)
