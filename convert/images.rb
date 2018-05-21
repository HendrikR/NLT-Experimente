class File
  def write32(x); self.write [x].pack("L<"); end
  def write16(x); self.write [x].pack("S<"); end
  def write08(x); self.write [x].pack("C"); end
  def read32(); self.read(4).unpack1("L<"); end
  def read16(); self.read(2).unpack1("S<"); end
  def read08(); self.read(1).unpack1("C"); end
end

class Palette
  attr_accessor :r, :g, :b
  def initialize(r_,g_,b_)
    r = r_
    g = g_
    b = b_
  end
end

class Rect
  attr_accessor :x0, :y0, :width, :height
end

class Image
  # A single image with a palette and minimal metadata
  attr_accessor :name, :dimensions, :palette, :data, :compressed_data, :parent

  def sanity_checks
    pre = "sanity check failed: "
    data_size = @dimensions.width + @dimensions.height
    raise(pre + "image should have #{data_size} pixels, but has #{@data.size} instead") if @data.size != data_size
    raise(pre + "invalid palette size: should be 256, is #{@palette.size}") if @palette_size != 256
    # TODO: more sanity checks, also for the other classes
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

