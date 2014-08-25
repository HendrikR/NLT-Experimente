# -*- coding: utf-8 -*-
f = File.open(ARGV[0])
TYPUS = ["Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]

def weapon_blacklist(f) # TODO: Nur für C2.00 (Engl)
  f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.LTX", "rb", :encoding => "CP437")
  
  def name_s(name)
    arr = name.split('.')
    if arr.size == 1 then arr[0]
    else arr[0]+arr[1]; end
  end
  
  items = f_name.read.split("\0")
  items = items.inject([]) {|arr,i| arr << name_s(i)}
  f.seek(0x277FF)
  for i in 0...12
    puts "    #### #{TYPUS[i]}:"
    loop do
      id = f.read(2).unpack("S<")[0]
      break if id == 0xFFFF
      printf("- %s [%04x]\n", items[id], id)
    end
  end
end


weapon_blacklist(f)
f.close
