require './images.rb'

class BOB_OLD < ImageGroup
  def read(filename)
    file = File.open(filename, IO::BINARY)
    file.close
  end

  def write(filename)
    file = File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)
    file.close
  end
end
