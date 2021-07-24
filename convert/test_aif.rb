# coding: utf-8
require './aif.rb'
require './compression.rb'
require 'test/unit'
require './test_images.rb'

$testdir = "test_data"
$testfiles = ['WUERFEL.AIF',  # DSA2, subformat 03
              'MAG_BOOK.AIF', # DSA3, subformat 03
              'POOLMASK.AIF', # DSA3, subformat 02
              'BIN1PAL.AIF',  # DSA2, subformat 00, palette only
              'DRAGON_2.AIF', # DSA2, subformat 03
              'ORKLAND.AIF',  # DSA2, subformat 00, fullscreen
             ]

class TestAIF < Test::Unit::TestCase
  def setup
    @aif = AIF.new
  end

  def teardown
  end

  def make_basic_aif(subformat)
    img_in = Image.new()
    img_in.subformat = subformat
    img_in.dimensions = Rect.new(0, 0, 30, 20)
    def t4(x) (x/4)*4; end
    img_in.palette = []; 256.times{ |i| img_in.palette << Palette.new(t4(i), t4(255-i), t4(0x77)) }
    img_in.data = generate_random_pixels(img_in.dimensions.width, img_in.dimensions.height)
    return img_in
  end

  
  def test_load_aif
    for file in $testfiles do
      filename = $testdir + "/" + file
      puts "  testing file #{filename}"
      img_out = @aif.read(filename)
      assert_true( img_out.sanity_checks )
    end
  end

  def readwrite_mode_test(mode)
    filename = "#{$testdir}/out_mode#{mode}.aif"
    img_in = make_basic_aif(mode)

    @aif.write(filename, img_in)
    assert_true(img_in.sanity_checks)

    img_out = @aif.read(filename)
    assert_true(img_out.sanity_checks)

    system "rm #{filename}"

    return [img_in, img_out]
  end

  def test_readwrite_mode0
    img_in, img_out = readwrite_mode_test(0)
    assert_equal(img_in, img_out)
  end

  def notest_readwrite_mode1
    img_in, img_out = readwrite_mode_test(1)
    assert_equal(img_in, img_out)
  end

  def notest_readwrite_mode2
    img_in, img_out = readwrite_mode_test(2)
    assert_equal(img_in, img_out)
  end

  def notest_readwrite_mode3
    img_in, img_out = readwrite_mode_test(3)
    assert_equal(img_in, img_out)
  end

end
