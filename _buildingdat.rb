# -*- coding: utf-8 -*-
class Building
  attr_accessor :name
  def initialize(name)
    @name = name
    case name
    when "HEALER"
      @keys = ["u1", "u2", "u3", "u4", "anim_variant"]
    when "INN"
      @keys = ["u1", "u2", "u3", "u4", "u5", "anim_variant"]
    when "SHOP"
      @keys = ["u1", "u2", "u3", "u4", "u5", "u6", "u7", "u8", "u9", "uA", "uB", "anim_variant"]
    when "SMITH"
      @keys = ["u1", "u2", "u3", "anim_variant"]
    when "TAVERN"
      @keys = ["u1", "u2", "u3", "u4", "u5", "u6", "u7"]
    when "TEMPLE"
      @keys = ["anim_variant"]
    else
      puts "Fehler: Unbekannter Gebäudetyp #{name}"
      exit
    end
    @vals = Array.new(@keys.size)
  end
  def getKey(key); return @keys[key]; end
  def setKey(key, val); @keys[key] = val; end
  def setAllKeys(vals)
    @vals = vals
  end
  def size; @keys.size; end
  def getHash; @keys.zip(@vals); end
end

exit if ARGV.size < 1

name = ARGV[0].split(".")[0].upcase
b = Building.new(name)
datasize = b.size
f = File.new(name + ".DAT", "rb")

buildings = []
while (data = f.read(datasize)) != nil
  data = data.bytes
  buildings << Building.new(name)
  buildings.last.setAllKeys(data)
end

buildings.each_with_index{ |b,i|
  printf "%s %d:", b.name, i
  b.getHash.each{ |key,val| printf "\t%d", val }
  puts
}

f.close
