require 'test/unit'
require './compression.rb'


class TestCompression < Test::Unit::TestCase
  def test_bitreader
    data_in = Array.new(16){|i| 11*i}
    bits = ReverseBitReader.new(data_in)
    data_out = []
    (data_in.size).times{
      data_out << bits.read(8)
    }
    assert_equal( data_in.reverse, data_out )
  end
end
# TODO: more tests (compression-decompression equality under random streams for every algorithm)
