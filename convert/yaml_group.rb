require './images.rb'
require './formats.rb'
require 'yaml'

class YAML_DIR < ImageHandler
  def initialize(img_format)
    @img_format = img_format
    @formatter = TGA.new
  end
  def read(filename)
    img_group = YAML::parse_file(filename).to_ruby
    img_group.parts.map{|part|
      part.images.map{|img|
        name = img.data
        yield @formatter.read(name)
      }
    }
  end
  def write(dirname, img_group)
    Dir::mkdir(dirname) unless Dir::exists?(dirname)
    img_group.parts.each{|part|
      idx = 0
      part.images.each{|img|
        idx += 1
        img.name = ("%04d" % idx) if img.name.empty?
        old_subformat = img.subformat
        img.subformat = 9
        img_file = "#{dirname}/img-#{part.name}-#{img.name}.tga" # TODO: respect @img_format
        ##puts "write #{img_file}"
        @formatter.write(img_file, img)

        # this is saved in the image file
        img.data = img_file
        img.compressed_data = nil
        img.palette = nil
        img.subformat = old_subformat
      }
    }
    file = File.new("#{dirname}/meta.yaml", IO::CREAT | IO::WRONLY)
    file.write(img_group.to_yaml)
    file.close()
  end
end
