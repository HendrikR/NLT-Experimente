require './bob_new.rb'
require './bob_old.rb'
require 'test/unit'
require './test_images.rb'

$testfiles = {'alatz1_new' => 'test_data/ALATZ1.BOB',
              'temple_old' => 'test_data/TEMPLE.BOB',
              'rw_new' => 'test_data/out_new.bob',
              'rw_old' => 'test_data/out_old.bob',
             }

class TestBOB < Test::Unit::TestCase
  def setup
    # TODO maybe delete leftover test files
  end

  def teardown
  end

  def test_load_bob_old
    img_out = BOB_OLD.new()
    img_out.read($testfiles['temple_old'])
    assert_true( img_out.sanity_checks )
  end

  def test_load_bob_new
    img_out = BOB_NEW.new()
    img_out.read($testfiles['alatz1_new'])
    assert_true( img_out.sanity_checks )
  end

  def make_bob(testfile, bob_variant)
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
    bobby.write(testfile)
    return bobby
  end

  def test_readwrite_new
    # TODO
  end

  # TODO: more tests
end