require './ace.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'jaeger' => 'test_data/JAEGER.ACE',
              # TODO: add more, diverse test images.
              'rw_rle' => 'test_data/out_rle.ace',
             }

class TestACE < Test::Unit::TestCase
  def setup
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_ace
    img_out1 = ACE.new()
    img_out1.read($testfiles['jaeger'])
    assert_true( img_out1.sanity_checks )
  end

  def make_basic_ace(testfile, ace_variant)
    # TODO: something with the variant ...
    ace = ACE.new()
    ace.anim_speed = 1
    ace.dimensions = Rect.new(0, 0, 0, 0) # Type 1 image lists have per-image dimensions -- this should (hopefully) be ignored (but we need the values to match with img[0].dimensions for the test to pass)
    ace.palette = []; 256.times{ |i| ace.palette << Palette.new(i, 255-i, 0x77) }
    ace.parts = [ ImageList.new, ImageList.new ]
    ace.parts[0].name = "TST1"
    ace.parts[1].name = "TST2"
    8.times{ |i|
      img = Image.new
      img.name = ""
      img.dimensions = Rect.new(0,0, 40*i, 30*i)
      img.palette = ace.palette
      img.data = generate_random_pixels(img.dimensions.width, img.dimensions.height)
      ace.parts[i%2].images << img
    }
    ace.write(testfile)
    return ace
  end

  def test_readwrite_mode1
    imgs_in = make_basic_ace($testfiles['rw_rle'], 0)

    imgs_out = ACE.new()
    imgs_out.read($testfiles['rw_rle'])

    assert_equal(imgs_in, imgs_out)
  end

  # TODO: more tests
end
