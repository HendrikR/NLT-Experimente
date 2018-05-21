require 'optparse' # https://ruby-doc.org/stdlib-2.5.0/libdoc/optparse/rdoc/OptionParser.html


=begin
Format:
convert FROM.BOB TO/
=end

class Format
  @@formats = {}

  def Read(filename)
    raise 'Unknown format.'
  end

  def Write(filename)
    raise 'Unknown format.'
  end
end

def parse_options # TODO: just stupid examles for now
  options = {}
  OptionParser.new do |opt|
    opt.banner = "Usage: ./ful humin"
    opt.on('-f', '--force', 'Force it') { |o| options[:force] = o }
    opt.on('-t', '--target TARGET [String]', 'The target') { |o| options[:target] = o }
    opt.on('-b', '--buddy YESNO [FalseClass]', ''){|o| options[:buddy]=o} # o is converted to Boolean, defaulting to False
    opt.on('-a ARR [Array]') {} # you can have arrays: -a 1,2,3
  end.parse!
  return options
end

def determine_formats
end

format = BOB.new

def main()
  parse_options
  in_fmt, out_fmt = determine_formats
end
