require './tga.rb'
require 'test/unit'

$testfiles = {'readwrite_raw' => 'test_rw_raw.tga',
              'readwrite_rle' => 'test_rw_rle.tga'
             }

class TestTGA < Test::Unit::TestCase


  def setup
    # TODO init image with sensible header data & (pseudo-)random pixel sequence
    # TODO maybe delete leftover test files
  end

  def teardown
    # Test files are deleted on setup, not on teardown. This way, we can debug the contents if the test fails.
  end

  def generate_random_pixels(width, height)
    out = []
    (width * height).times{ out << rand(256) }
    return out
  end

  def generate_rle_pixels(width, height)
    out = []
    points = width*height
    1000.times{ out << 12 }; points -= 1000  # start with 1000 same-colored pixels
    10.times{|x| out << 200+x }; points -= 10  # 10 pixels of colors >= 0x80
    (points-(2*width)).times{ out << rand(256) } # random stuff
    (2*width).times{ out << 99 } # finish off with 2 lines of same-colored pixels
    return out
  end

  def compare_images(img_in, img_out)
    assert_true(img_in.sanity_checks)
    assert_true(img_out.sanity_checks)

    assert_equal(img_in.name, img_out.name)
    assert_equal(img_in.dimensions, img_out.dimensions)
    assert_equal(img_in.palette, img_out.palette)
    assert_equal(img_in.data, img_out.data)
  end

  def test_readwrite_raw
    img_in = TGA.new()
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_random_pixels(img_in.dimensions.width, img_in.dimensions.height)
    img_in.write($testfiles['readwrite_raw'])

    img_out = TGA.new()
    img_out.read($testfiles['readwrite_raw'])

    compare_images(img_in, img_out)
  end

  def test_readwrite_rle
    # TODO: Do /actual/ RLE compression.
    img_in = TGA.new()
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_rle_pixels(img_in.dimensions.width, img_in.dimensions.height)
    img_in.write($testfiles['readwrite_rle'])

    img_out = TGA.new()
    img_out.read($testfiles['readwrite_rle'])

    # TODO: compare @img01 and img_out: header and pixel data. Is this the way to go?
    compare_images(img_in, img_out)
  end
end
