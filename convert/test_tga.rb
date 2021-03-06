require './tga.rb'
require './compression.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'readwrite_raw' => 'test_data/out_raw.tga',
              'readwrite_rle' => 'test_data/out_rle.tga',
              'xkcd'          => 'test_data/borrow_your_laptop.tga'
             }

class TestTGA < Test::Unit::TestCase
  def setup
    @tga = TGA.new
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_real_tga
    img = @tga.read($testfiles['xkcd'])
    assert_true(img.sanity_checks)
  end

  def test_recompress_rle2
    tga = Image.new
    data = generate_random_pixels(234, 123)
    comp = compress_rle2(data)
    dcmp = decompress_rle2(comp)
    assert_equal( data, dcmp )
  end

  def test_readwrite_raw
    img_in = Image.new()
    img_in.subformat = TGA::compression_mode_id :raw
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_random_pixels(img_in.dimensions.width, img_in.dimensions.height)

    @tga.write($testfiles['readwrite_raw'], img_in)
    assert_true(img_in.sanity_checks)

    img_out = @tga.read($testfiles['readwrite_raw'])
    assert_true(img_out.sanity_checks)

    assert_equal(img_in, img_out)
  end

  def test_readwrite_rle
    img_in = Image.new()
    img_in.subformat = TGA::compression_mode_id :rle2
    img_in.name = "Dieses Bild hat einen langen Namen, aber nicht zu lang."
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_rle_pixels(img_in.dimensions.width, img_in.dimensions.height)

    @tga.write($testfiles['readwrite_rle'], img_in)
    assert_true(img_in.sanity_checks)

    img_out = @tga.read($testfiles['readwrite_rle'])
    assert_true(img_out.sanity_checks)

    assert_equal(img_in, img_out)
  end
end
