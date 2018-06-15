require './tga.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'readwrite_raw' => 'test_data/out_raw.tga',
              'readwrite_rle' => 'test_data/out_rle.tga',
              'xkcd'          => 'test_data/borrow_your_laptop.tga'
             }

class TestTGA < Test::Unit::TestCase
  def setup
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_real_tga
    img = TGA.new()
    img.read($testfiles['xkcd'])
    assert_true(img.sanity_checks)
  end

  def test_recompress_rle
    tga = TGA.new
    data = generate_random_pixels(234, 123)
    comp = tga.compress_rle(data)
    dcmp = tga.decompress_rle(comp)
    assert_equal( data, dcmp )
  end

  def test_readwrite_raw
    img_in = TGA.new()
    img_in.compression = :raw
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_random_pixels(img_in.dimensions.width, img_in.dimensions.height)
    img_in.write($testfiles['readwrite_raw'])
    assert_true(img_in.sanity_checks)

    img_out = TGA.new()
    img_out.read($testfiles['readwrite_raw'])
    assert_true(img_out.sanity_checks)

    assert_equal(img_in, img_out)
  end

  def test_readwrite_rle
    img_in = TGA.new()
    img_in.compression = :rle
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_rle_pixels(img_in.dimensions.width, img_in.dimensions.height)
    img_in.write($testfiles['readwrite_rle'])
    assert_true(img_in.sanity_checks)

    img_out = TGA.new()
    img_out.read($testfiles['readwrite_rle'])
    assert_true(img_out.sanity_checks)

    rng = 59998..60005
    assert_equal(img_in.data[rng], img_out.data[rng]) # todo
  end
end
