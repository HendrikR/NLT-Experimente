class File
  def write32(x); self.write [x].pack("L<"); end
  def write16(x); self.write [x].pack("S<"); end
  def write08(x); self.write [x].pack("C"); end
  # TODO: use unpack1() when available
  def read32(); self.read(4).unpack("L<")[0]; end
  def read16(); self.read(2).unpack("S<")[0]; end
  def read08(); self.read(1).unpack("C")[0]; end
end

class Palette
  attr_accessor :r, :g, :b
  def initialize(r,g,b)
    @r = r
    @g = g
    @b = b
  end

  def ==(o)
    @r == o.r && @g == o.g && @b == o.b
  end
end

class Rect
  attr_accessor :x0, :y0, :width, :height
  def initialize(x0, y0, width, height)
    @x0     = x0
    @y0     = y0
    @width  = width
    @height = height
  end

  def size
    @width * @height
  end

  def ==(o)
    @x0 == o.x0 && @y0 == o.y0 && @width = o.width && @height == o.height
  end
end

class Image
  # A single image with a palette and minimal metadata
  attr_accessor :name, :dimensions, :palette, :data, :compressed_data, :parent

  def sanity_checks
    pre = "sanity check failed: "
    raise(pre + "image should have #{@dimensions.size} pixels, but has #{@data.size} instead") if @data.size != @dimensions.size
    raise(pre + "invalid palette size: should be 256, is #{@palette.size}") if @palette.size != 256
    # TODO: more sanity checks, also for the other classes
    return true
  end
end

class ImageList
  # A flat list of images, with some metadata
  attr_accessor :name, :dimensions, :palette, :images, :parent
end

class ImageGroup
  # A group containing named lists of images
  attr_accessor :name, :dimensions, :palette, :parts
end

