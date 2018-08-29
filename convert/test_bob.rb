require './bob_new.rb'
require './bob_old.rb'
require 'test/unit'
require './test_images.rb'

$testdir = "test_data"
$testfiles = {'alatz1_new' => 'test_data/ALATZ1.BOB',
              'lana_new' => 'test_data/LANA.BOB',
              'temple_old' => 'test_data/TEMPLE.BOB',
             }

class TestBOB < Test::Unit::TestCase
  def setup
    @bob_new = BOB_NEW.new
    @bob_old = BOB_OLD.new
  end

  def test_load_bob_old
    img_out = @bob_old.read($testfiles['temple_old'])
    assert_true( img_out.sanity_checks )
  end

  def notest_load_bob_new
    #img_out = @bob_new.read($testfiles['alatz1_new'])
    img_out = @bob_new.read("test_data/ELAJA.BOB")
    assert_true( img_out.sanity_checks )
  end

  def make_bob(bob_variant)
    case bob_variant
    when :old then bobby = BOB_OLD.new
    when :new then bobby = BOB_NEW.new
    else raise "Corrupted test: no such BOB variant #{bob_variant}"
    end

    bobby.dimensions = Rect.new(0, 0, 0, 0) # Type 1 image lists have per-image dimensions -- this should (hopefully) be ignored (but we need the values to match with img[0].dimensions for the test to pass)
    bobby.palette = []; 256.times{ |i| bobby.palette << Palette.new(i, 255-i, 0x77) }
    bobby.parts = [ ImageList.new, ImageList.new ]
    bobby.parts.list[0].name = "TST1"
    bobby.parts.list[1].name = "TST2"
    8.times{ |i|
      img = Image.new
      img.name = ""
      img.dimensions = Rect.new(0,0, 40*i, 30*i)
      img.palette = bobby.palette
      img.data = generate_random_pixels(img.dimensions.width, img.dimensions.height)
      bobby.parts[i%2].images << img
    }
    return bobby
  end

  def readwrite_mode_test(variant)
    handler = bob_variant == :old  ?  @bob_old  :  @bob_new
    filename = "#{$testdir}/out_#{variant}.bob"
    img_in = make_basic_bob(variant)

    handler.write(filename, img_in)
    assert_true(img_in.sanity_checks)

    img_out = handler.read(filename)
    assert_true(img_out.sanity_checks)

    system "rm #{filename}"

    return [img_in, img_out]
  end

  def notest_readwrite_old
    img_in, img_out = readwrite_mode_test(:old)
    assert_equal(img_in, img_out)
  end

  def notest_readwrite_new
    img_in, img_out = readwrite_mode_test(:new)
    assert_equal(img_in, img_out)
  end
end
