require './aif.rb'
require './compression.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'readwrite_raw' => 'test_data/out_raw.aif',
             }

# TODO: test pp, format aif_0x02

class TestAIF < Test::Unit::TestCase
  def setup
    @aif = AIF.new
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def notest_load_real_aif
    img = @aif.read($testfiles['...']) # TODO: add some real AIFs
    assert_true(img.sanity_checks)
  end

  def test_readwrite_raw
    img_in = Image.new()
    img_in.subformat = 0x00
    img_in.dimensions = Rect.new(0, 0, 30, 20)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_random_pixels(img_in.dimensions.width, img_in.dimensions.height)

    @aif.write($testfiles['readwrite_raw'], img_in)
    assert_true(img_in.sanity_checks)

    img_out = @aif.read($testfiles['readwrite_raw'])
    assert_true(img_out.sanity_checks)

    assert_equal(img_in, img_out)
  end
end
