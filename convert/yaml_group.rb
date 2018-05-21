require 'images.rb'
require 'yaml'

class YAML_DIR < ImageGroup
  def initialize(format)
    @format = format
  end
  def read(filename)
    @metadata = YAML::parse_file(filename).to_ruby
  end
  def write(filename)
    file = File.new(filename, IO::CREATE | IO::WRONLY)
    file.write(@metadata.to_yaml)
    file.close()
  end
end
