require './nvf.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'rw_mode0' => 'test_data/out_mode0.nvf',
              'rw_mode1' => 'test_data/out_mode1.nvf',
              'horse0'        => 'test_data/HORSE0.NVF'
             }

class TestNVF < Test::Unit::TestCase


  def setup
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_nvf
    img_out = NVF.new()
    img_out.read($testfiles['horse0'])
    assert_true( img_out.sanity_checks )
  end

  def make_basic_nvf(testfile, nvf_type)
    imgs_in = NVF.new()
    imgs_in.nvf_type = nvf_type
    imgs_in.dimensions = Rect.new(0, 0, 0, 0) # Type 1 image lists have per-image dimensions -- this should (hopefully) be ignored (but we need the values to match with img[0].dimensions for the test to pass)
    imgs_in.palette = []; 256.times{ |i| imgs_in.palette << Palette.new(i, 255-i, 0x77) }
    imgs_in.images = []
    4.times{ |i|
      img = Image.new
      img.name = ""
      img.dimensions = Rect.new(0,0, 40*i, 30*i)
      img.palette = imgs_in.palette
      img.data = generate_random_pixels(img.dimensions.width, img.dimensions.height)
      imgs_in.images << img
    }
    imgs_in.write(testfile)
    return imgs_in
  end

  def test_readwrite_mode0
    imgs_in = make_basic_nvf($testfiles['rw_mode0'], 0)

    imgs_out = NVF.new()
    imgs_out.read($testfiles['rw_mode0'])

    assert_equal(imgs_in, imgs_out)
  end

  def test_readwrite_mode1
    imgs_in = make_basic_nvf($testfiles['rw_mode1'], 0)

    imgs_out = NVF.new()
    imgs_out.read($testfiles['rw_mode1'])

    assert_equal(imgs_in, imgs_out)
  end

=begin
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
=end
end
