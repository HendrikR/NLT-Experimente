require 'test/unit'

def generate_random_pixels(width, height)
  #srand(1) # TODO!!!
  out = []
  (width * height).times{ out << rand(256) }
  return out
end

def generate_rle_pixels(width, height)
  srand(1) # TODO!!!
  out = []
  points = width*height
  1000.times{ out << 12 }; points -= 1000  # start with 1000 same-colored pixels
  10.times{|x| out << 200+x }; points -= 10  # 10 pixels of colors >= 0x80
  (points-(20*width)).times{ out << rand(128) } # random stuff
  (20*width).times{ out << 12 } # finish off with 2 lines of same-colored pixels
  return out
end

