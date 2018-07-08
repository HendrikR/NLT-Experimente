require './images.rb'

class BOB_OLD < ImageHandler
  def read(filename)
    bob  = ImageGroup.new
    file = File.open(filename, IO::BINARY)

    file.close
    return bob
  end

  def write(filename, bob)
    file = File.open(filename, IO::CREAT | IO::WRONLY | IO::TRUNC | IO::BINARY)

    file.close
  end
end
