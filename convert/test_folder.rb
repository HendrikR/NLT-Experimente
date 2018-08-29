require './formats.rb'

dir_name = (ARGV[0] or "./")
dir = Dir.new(dir_name)

h_tga = $EXTENSION_HANDLERS["TGA"]

dir.select{|f|
  FileTest.file?(dir_name +"/"+ f)
}.each{|filename|
  extension = filename.match(/\.([^.]+)/) # everything after the last dot
  next if not extension

  extension = extension[1]
  handler = $EXTENSION_HANDLERS[extension.upcase]
  next if not handler

  fullname = dir_name + filename
  puts "reading #{fullname}"
  img = handler.read(fullname)
  raise "Sanity check failed." if not img.sanity_checks
#  out_fullname = fullname.sub(Regexp.new(extension+"$"), "tga")
#  img.subformat = 9
#  h_tga.write(out_fullname, img)
}
