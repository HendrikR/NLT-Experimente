require './nvf.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'rw_mode0' => 'test_data/out_mode0.nvf',
              'rw_mode1' => 'test_data/out_mode1.nvf',
              'rw_mode2' => 'test_data/out_mode2.nvf',
              'rw_mode3' => 'test_data/out_mode3.nvf',
              'rw_mode4' => 'test_data/out_mode4.nvf',
              'rw_mode5' => 'test_data/out_mode5.nvf',
              'horse0'        => 'test_data/HORSE0.NVF'
             }

class TestNVF < Test::Unit::TestCase
  def setup
    @nvf = NVF.new
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_nvf
    img_out = @nvf.read($testfiles['horse0'])
    assert_true( img_out.sanity_checks )
  end

  def make_basic_nvf(subformat)
    imgs_in = ImageList.new()
    imgs_in.subformat = subformat
    if @nvf.uniform_resolution?(imgs_in)
      imgs_in.dimensions = Rect.new(0,0, 40, 30)
      3.times{ |i|
        img = Image.new
        img.name = ""
        img.dimensions = imgs_in.dimensions
        img.palette = imgs_in.palette
        img.data = generate_rle_pixels(img.dimensions.width, img.dimensions.height)
        imgs_in.images << img
      }
    else
      imgs_in.dimensions = Rect.new(0, 0, 0, 0) # Type 1 image lists have per-image dimensions -- this should (hopefully) be ignored (but we need the values to match with img[0].dimensions for the test to pass)
      imgs_in.palette = []; 256.times{ |i| imgs_in.palette << Palette.new(i, 255-i, 0x77) }
      imgs_in.images = []
      3.times{ |i|
        img = Image.new
        img.name = ""
        img.dimensions = Rect.new(0,0, 40*i, 30*i)
        img.palette = imgs_in.palette
        img.data = generate_rle_pixels(img.dimensions.width, img.dimensions.height)
        imgs_in.images << img
      }
    end
    return imgs_in
  end

  def test_readwrite_mode0
    imgs_in = make_basic_nvf(0)
    @nvf.write($testfiles['rw_mode0'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode0'])

    assert_equal(imgs_in, imgs_out)
  end

  def test_readwrite_mode1
    imgs_in = make_basic_nvf(1)
    @nvf.write($testfiles['rw_mode1'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode1'])

    assert_equal(imgs_in, imgs_out)
  end

  # TODO: enable once pp (de-)compression is supported
  def notest_readwrite_mode2
    imgs_in = make_basic_nvf(2)
    @nvf.write($testfiles['rw_mode2'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode2'])

    assert_equal(imgs_in, imgs_out)
  end

  # TODO: enable once pp (de-)compression is supported
  def notest_readwrite_mode3
    imgs_in = make_basic_nvf(3)
    @nvf.write($testfiles['rw_mode3'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode3'])

    assert_equal(imgs_in, imgs_out)
  end

  def test_readwrite_mode4
    imgs_in = make_basic_nvf(4)
    @nvf.write($testfiles['rw_mode4'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode4'])

    assert_equal(imgs_in, imgs_out)
  end

  def test_readwrite_mode5
    imgs_in = make_basic_nvf(5)
    @nvf.write($testfiles['rw_mode5'], imgs_in)

    imgs_out = @nvf.read($testfiles['rw_mode5'])

    assert_equal(imgs_in, imgs_out)
  end
end
