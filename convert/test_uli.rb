require './uli.rb'
require './compression.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'readwrite' => 'test_data/out.uli',
              'font-1bit' => 'test_data/FNT16.ULI',
              'tlogo'     => 'test_data/TLOGO.ULI'
             }

class TestULI < Test::Unit::TestCase
  def setup
    @uli = ULI.new
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def notest_readwrite
    img_in = Image.new()
    img_in.subformat = 0
    img_in.name = ""
    img_in.dimensions = Rect.new(0, 0, 300, 200)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_rle_pixels(img_in.dimensions.width, img_in.dimensions.height)

    @uli.write($testfiles['readwrite'], img_in)
    assert_true(img_in.sanity_checks)

    img_out = @uli.read($testfiles['readwrite'])
    assert_true(img_out.sanity_checks)

    assert_equal(img_in, img_out) # todo
  end

  def test_load_uli_1bit
    img_out = @uli.read($testfiles['font-1bit'])
    assert_true( img_out.sanity_checks )
  end

  def test_load_uli_color
    img_out = @uli.read($testfiles['tlogo'])
    assert_true( img_out.sanity_checks )
  end
end
