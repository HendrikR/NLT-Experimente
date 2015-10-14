# -*- coding: utf-8 -*-
class Building
  attr_accessor :name, :size, :fields, :vals
  def initialize(name)
    @name = name
    case name
    when "HEALER"
      @size = 5
      @fields = [["Preis: %d%%", "s<"],
                 ["Fehlerschlag zu %d%%", "C"],
                 ["Bild %d", "C"],
                 ["Heilt Versteinerung: %d", "C"]]
    when "INN"
      @size = 6
      @fields = [["Preis: %d%%", "s<"],
                 ["Qualität %d", "C"],
                 ["? %d", "C"],
                 ["Zimmer frei zu %d%%", "C"],
                 ["Bild %d", "C"]]
    when "SHOP"
      @size = 13
      @fields = [["Kaufpreise: %d%%", "s<"],
                 ["Verkaufspreise: %d%%", "s<"],
                 ["Ladentyp %d", "C"],
                 ["Sortiment %d", "C"],
                 ["Zusatzitem-ID 1: %d", "S<"],
                 ["Zusatzitem-ID 2: %d", "S<"],
                 ["Zusatzitem-ID 3: %d", "S<"],
                 ["Bild %d", "C"]]
    when "SMITH"
      @size = 4
      @fields = [["Preis: %d%%", "s<"], ["Qualität %d", "C"], ["Bild %d", "C"]]
    when "TAVERN"
      @size = 4
      @fields = [["Preis: %d%%", "s<"], ["Qualität %d", "S<"], ["Bild %d", "C"], ["?: %d", "S<"]]
    when "TEMPLE"
      @size = 4
      @fields = [["Bild/Geschlecht %d", "C"]]
    else
      puts "Fehler: Unbekannter Gebäudetyp #{name}"
      exit
    end
    @vals = Array.new(@fields.size)
  end
  def getKey(key); return @fields[key][0]; end
  def setAllKeys(vals)
    formatstr = @fields.inject(""){|out, field| out+=field[1]}
    @vals = vals.unpack(formatstr)
  end
  def getHash
    @fields.collect{|key,fmt| key}.zip(@vals)
  end
end

exit if ARGV.size < 1

name = ARGV[0].match("([^/.]*).DAT")[1].upcase
b = Building.new(name)
datasize = b.size
f = File.new(ARGV[0], "rb")

buildings = []
while (data = f.read(datasize)) != nil
  buildings << Building.new(name)
  buildings.last.setAllKeys(data)
end

buildings.each_with_index{ |b,i|
  printf "%s %d:", b.name, i
  for i in 0...b.fields.size do
    printf("\t" + b.fields[i][0], b.vals[i])
  end
  puts
}

f.close
