# coding: utf-8
class File
  def write32(x); self.write [x].pack("L<"); end
  def write16(x); self.write [x].pack("S<"); end
  def write08(x); self.write [x].pack("C"); end
  def writeS32(x); self.write [x].pack("l<"); end
  def writeS16(x); self.write [x].pack("s<"); end
  def writeS08(x); self.write [x].pack("c"); end
  # TODO: use unpack1() when available
  def read32(); self.read(4).unpack("L<")[0]; end
  def read16(); self.read(2).unpack("S<")[0]; end
  def read08(); self.read(1).unpack("C")[0]; end
  def readS32(); self.read(4).unpack("l<")[0]; end
  def readS16(); self.read(2).unpack("s<")[0]; end
  def readS08(); self.read(1).unpack("c")[0]; end
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

  def to_s
    "(#{@width}×#{@height}) at (#{@x0}, #{@y0})"
  end
end

class Image
  # A single image with a palette and minimal metadata
  attr_accessor :name, :dimensions, :palette, :data, :compressed_data, :parent, :subformat

  def initialize
    @name = ""
    @dimensions = Rect.new(0,0, 0,0)
    @palette = []
    @data = []
    @compressed_data = []
    @parent = nil
    @subformat = 0
  end

  def sanity_checks
    pre = "sanity check failed: "
    raise(pre + "image should have #{@dimensions.size} pixels, but has #{@data.size} instead") if @data.size != @dimensions.size
    raise(pre + "invalid palette size: should be =<256, is #{@palette.size}") if @palette == nil || @palette.size > 256
    # TODO: more sanity checks
    return true
  end

  def ==(other)
    return false if @name != other.name
    return false if @dimensions != other.dimensions
    return false if @palette != other.palette
    return false if @data != other.data
    return true
  end

end

class ImageList
  # A flat list of images, with some metadata
  attr_accessor :name, :dimensions, :palette, :images, :parent

  attr_accessor :playmode, :subformat # TODO: sync this with all formats

  def initialize
    @name = ""
    @dimensions = Rect.new(0,0, 0,0)
    @palette = []
    @images = []
    @parent = nil

    @playmode = 0
    @subformat = 0
  end

  def sanity_checks
    raise "High number of subimages (#{@images.size}) seems flaky." if @images.size > 60 # TODO: this is not a good sanity check, remove it after reaching stability.

    for img in @images do
      img.sanity_checks
    end

    for img in @images do
      if img.dimensions.x0 + img.dimensions.width > @dimensions.width or
        img.dimensions.y0 + img.dimensions.height > @dimensions.height
        # TODO: check lower bounds?
        raise "Image dimensions [#{img.dimensions}] violate ImageList borders [#{@dimensions}]."
      end
    end

    # TODO: more sanity checks
    return true
  end

  def ==(other)
    return false if @name != other.name
    return false if @dimensions != other.dimensions
    return false if @palette != other.palette
    return false if @images.size != other.images.size
    @images.size.times{ |i|
      return false if @images[i] != other.images[i]
    }
    return true
  end

end

class ImageGroup
  # A group containing named lists of images
  attr_accessor :name, :dimensions, :palette, :parts, :subformat
  attr_accessor :anim_speed # for ACE

  def initialize
    @name = ""
    @dimensions = Rect.new(0,0, 0,0)
    @parts = []
    @palette = []
    @subformat = 0
  end

  def sanity_checks
    raise "High number of subimages (#{@parts.size}) seems flaky." if @parts.size > 60 # TODO: this is not a good sanity check, remove it after reaching stability.

    for part in @parts do
      part.sanity_checks
    end

    for part in @parts do
      if part.dimensions.x0 + part.dimensions.width > @dimensions.width or
        part.dimensions.y0 + part.dimensions.height > @dimensions.height
        # TODO: check lower bounds
        raise "Part '#{part.name}' dimensions [#{part.dimensions}] violate ImageGroup borders [#{@dimensions}]."
      end
    end
    # TODO: more sanity checks
    return true
  end

  def ==(other)
    return false if @name != other.name
    return false if @dimensions != other.dimensions
    return false if @palette != other.palette
    return false if @parts.size != other.parts.size
    @parts.size.times{ |i|
      return false if @parts[i] != other.parts[i]
    }
    return true
  end
end

class ImageHandler
  def read(filename)
    raise "Abstract class, must derive subclass"
  end

  def write(filename, img)
    raise "Abstract class, must derive subclass"
  end
end
