# coding: utf-8
require './ace.rb'
require 'test/unit'
require './test_images.rb'

$testdir = "test_data"
$testfiles = ['JAEGER.ACE', ## DSA2: Kampfanimationen Jäger, subformat 50(pp)
              'A1_5_BOA.ACE', ## DSA3: Ruderboot-Animationsbildchen, subformat 1(rle) / 0(raw)
              'FEUERGEI.ACE', ## DSA3: Kampfanimationen, subformat 50(pp) / 1(rle)
             ]

class TestACE < Test::Unit::TestCase
  def setup
    @ace = ACE.new
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_ace
    for file in $testfiles do
      filename = $testdir + "/" + file
      puts "  testing file #{filename}"
      img_out = @ace.read(filename)
      assert_true( img_out.sanity_checks )
    end
  end

  def make_basic_ace(ace_variant)
    ace = ImageGroup.new()
    ace.subformat = ace_variant
    ace.anim_speed = 1
    ace.dimensions = Rect.new(0, 0, 40*7, 30*7) # Type 1 image lists have per-image dimensions -- this should (hopefully) be ignored (but we need the values to match with img[0].dimensions for the test to pass)

    def t4(x) (x/4)*4; end
    ace.palette = []; 256.times{ |i| ace.palette << Palette.new(t4(i), t4(255-i), t4(0x77)) }
    ace.parts = [ ImageList.new, ImageList.new ]
    ace.parts[0].name = "1"
    ace.parts[1].name = "2"
    ace.parts[0].palette = ace.parts[1].palette = ace.palette
    8.times{ |i|
      img = Image.new
      img.subformat = ace_variant
      img.dimensions = Rect.new(0,0, 40*i, 30*i)
      img.palette = ace.palette
      img.data = generate_random_pixels(img.dimensions.width, img.dimensions.height)
      ace.parts[i%2].images << img
      ace.parts[i%2].dimensions = img.dimensions
    }
    return ace
  end

  def readwrite_mode_test(mode)
    filename = "#{$testdir}/out_mode#{mode}.ace"
    img_in = make_basic_ace(mode)

    @ace.write(filename, img_in)
    assert_true(img_in.sanity_checks)

    img_out = @ace.read(filename)
    assert_true(img_out.sanity_checks)

    system "rm #{filename}"

    return [img_in, img_out]
  end

  def test_readwrite_mode0
    img_in, img_out = readwrite_mode_test(0)
    assert_equal(img_in, img_out)
  end

  def test_readwrite_mode1
    img_in, img_out = readwrite_mode_test(1)
    assert_equal(img_in, img_out)
  end

  def test_readwrite_mode2
    img_in, img_out = readwrite_mode_test(2)
    assert_equal(img_in, img_out)
  end

  # TODO: enable once pp compression is supported
  def notest_readwrite_mode50
    img_in, img_out = readwrite_mode_test(50)
    assert_equal(img_in, img_out)
  end

end
