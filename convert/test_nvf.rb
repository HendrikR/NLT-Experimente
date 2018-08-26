# coding: utf-8
require './nvf.rb'
require 'test/unit'
require './test_images.rb'

$testdir = "test_data"
$testfiles = ['HORSE0.NVF', ## DSA2
              'FONT.NVF',
              'NATURE.NVF', ## DSA2: Tileset
              'HEADS.NVF', ## DSA2: NSC-Köpfe
              'CHEADS2.NVF', ## DSA?: SC-Köpfe (krank)
             ]

class TestNVF < Test::Unit::TestCase
  def setup
    @nvf = NVF.new
  end

  def teardown
  end

  def test_load_nvf
    for file in $testfiles do
      filename = $testdir + "/" + file
      puts "  testing file #{filename}"
      img_out = @nvf.read(filename)
      assert_true( img_out.sanity_checks )
    end
  end

  def make_basic_nvf(subformat)
    imgs_in = ImageList.new()
    imgs_in.subformat = subformat
    # truncate palette entries to multiples of 4, because the lower two bits are lost in conversion
    def t4(x) (x/4)*4; end
    imgs_in.palette = []; 256.times{ |i| imgs_in.palette << Palette.new(t4(i), t4(255-i), t4(0x77)) }
    imgs_in.images = []
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
      3.times{ |i|
        img = Image.new
        img.name = ""
        img.dimensions = Rect.new(0,0, 40*i, 30*i)
        img.palette = imgs_in.palette
        img.data = generate_rle_pixels(img.dimensions.width, img.dimensions.height)
        imgs_in.images << img
      }
      # re-set dimensions to engulf image dimensions
      imgs_in.dimensions = Rect.new(0, 0, 40*(3-1), 30*(3-1))
    end
    return imgs_in
  end

  def readwrite_mode_test(mode)
    filename = "#{$testdir}/out_mode#{mode}.nvf"
    img_in = make_basic_nvf(mode)

    @nvf.write(filename, img_in)
    assert_true(img_in.sanity_checks)

    img_out = @nvf.read(filename)
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

  # TODO: enable once pp (de-)compression is supported
  def notest_readwrite_mode2
    img_in, img_out = readwrite_mode_test(2)
    assert_equal(img_in, img_out)
  end

  # TODO: enable once pp (de-)compression is supported
  def notest_readwrite_mode3
    img_in, img_out = readwrite_mode_test(3)
    assert_equal(img_in, img_out)
  end

  def test_readwrite_mode4
    img_in, img_out = readwrite_mode_test(4)
    assert_equal(img_in, img_out)
  end

  def test_readwrite_mode5
    img_in, img_out = readwrite_mode_test(5)
    assert_equal(img_in, img_out)
  end
end
