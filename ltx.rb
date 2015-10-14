# coding: utf-8
# Öffnet LTX-Dateien und zeigt den Inhalt mit Index an.
f = File.open(ARGV[0], "rb:CP850:utf-8")

line = 0
f.each("\0") {|str|
  line += 1
  str.gsub!("\u000d", "\\n")
  puts "0x#{line.to_s(16)}: #{str}"
}

