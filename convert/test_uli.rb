require './uli.rb'
require './compression.rb'
require 'test/unit'
require './test_images.rb'

$testdir = "test_data"

class TestULI < Test::Unit::TestCase
  def setup
    @uli = ULI.new
  end

  def test_readwrite
    filename = "#{$testdir}/out_8b.uli"
    img_in = Image.new()
    img_in.subformat = 0
    img_in.name = ""
    img_in.dimensions = Rect.new(0, 0, 4, 3)
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(i, 255-i, 0x77) }
    img_in.data = generate_rle_pixels(img_in.dimensions.width, img_in.dimensions.height)

    @uli.write(filename, img_in)
    assert_true(img_in.sanity_checks)

    img_out = @uli.read(filename)
    assert_true(img_out.sanity_checks)

    #assert_equal(img_in, img_out) # todo
    #system "rm #{filename}"

  end

  def test_load_uli_1bit # ULI file with 1-bit palette (black/white), uses smaller compression variant
    img_out = @uli.read("#{$testdir}/FNT16.ULI")
    assert_true( img_out.sanity_checks )
  end

  def test_load_uli_color
    img_out = @uli.read("#{$testdir}/TLOGO.ULI")
    assert_true( img_out.sanity_checks )
  end
end
