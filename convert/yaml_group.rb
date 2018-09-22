require './images.rb'
require 'yaml'

class YAML_DIR < ImageHandler
  def initialize(format)
    @format = format
  end
  def read(filename)
    @metadata = YAML::parse_file(filename).to_ruby
  end
  def write(filename, img_group)
    img_group.parts.map{|part|
      idx = 0
      part.images.map{|img|
        img.name = idx if img.name.empty?
        idx += 1
        img.
      }
    }
    puts img_group.to_yaml
    #file = File.new(filename, IO::CREATE | IO::WRONLY)
    #file.write(@metadata.to_yaml)
    #for 
    #file.close()
  end
end
