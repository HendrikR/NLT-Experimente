# -*- coding: utf-8 -*-
def readshort(file)
  return file.getbyte + (file.getbyte << 8)
end

class Tile
  attr_accessor :tile, :spid
  def initialize(m1,m2)
    @tile = m1
    @spid = m2
  end
end

class TileType
  attr_accessor :bldType, :direction, :unk1
  def initialize(b1,b2,b3)
    @bldType = b1
    @direction = b2
    # Unk1 ist vermutlich Cruft. Tjolmar hat z.B. kein Tile mit einem Wert != 0.
    # War evtl. mal ein Index in die .IDX-Beschreibungstabelle, denn die Werte sind innerhalb einer Karte eindeutig,
    # und die Anordnung entspricht grob der, in der die Gebäude in der .INF gelistet sind.
    @unk1 = b3
  end
end

def textcolor(tc)
  printf("\033[0;#{tc}m")
end


exit if ARGV.size < 1

f_mad = File.new(ARGV[0].upcase+".MAD", "rb")
f_dbg = File.new(ARGV[0].upcase+".DBG", "rb") # Dungeon
f_inf = File.new(ARGV[0].upcase+".INF", "rb")
f_cyb = File.new(ARGV[0].upcase+".CYB", "rb") # City

# CYB-Format
# Immer 3 Bytes pro Tile-Index, daher 3*256=768 Bytes groß.
# Byte 1 Gebäudetyp
# Byte 2 0x80-0x83, das 2 Nybble gibt die Richtung des Einganges an. Unklar, was bei anderen Werten passiert.
# Byte 3 unbekannt, ist meist (immer?) 0. Möglicherweise irgendein Index.

tiletypes = Array.new(256)
256.times{ |i| # Für jeden Tile-Index hat die .CYB einen 3-Byte-Eintrag.
  tiletypes[i] = TileType.new(f_cyb.getbyte, f_cyb.getbyte, f_cyb.getbyte)
}



width  = readshort(f_mad)
height = readshort(f_mad)

map = Array.new(height)
height.times{ |i|  map[i] = Array.new(width) }

puts "Map of #{width}x#{height}:"
for y in 0...height
  for x in 0...width
    map[y][x] = Tile.new(f_mad.getbyte, f_mad.getbyte)
  end
end

f_mad.close
f_dbg.close
f_inf.close
f_cyb.close

printf("    ")
for x in 0...width do printf "%02x ", x; end; puts


for y in 0...height
  #printf "%02x  ", y
  for x in 0...width
    # Tiles
    tile = map[y][x].tile
    spid = map[y][x].spid
    tlid = tiletypes[tile]
    # Die Zuordungen hier sind für Kvirasim, in anderen Städten sind die anders. Seltsam.
    # Was genau welcher Gebäudetyp macht, hängt wohl irgendwie mit in den 3D-Dateien:
    #   wenn ich 2 3D-Dateien austausche, ändert sich der Gebäudetyp?!
    # Bleibt die Frage: Woher weiß Schweif, welcher Gebäudetyp welche 3D-Datei aufruft???
    case tlid.bldType
    when 0x00 then textcolor("30;2") # Nichts
    when 0x01 then textcolor("32;2") # Gras
    when 0x02 then textcolor("34;2") # Wasser
    when 0x03 then textcolor("34;2") # Wasser
    when 0x04 then textcolor("31;2") # Schänke
    when 0x05 then textcolor("33;1") # Tempel
    when 0x06 then textcolor("37;1") # unbekannt/buggy
    when 0x07 then textcolor("36;1") # Händler (Kräuter)
    when 0x08 then textcolor("32;2") # Baum
    when 0x09 then textcolor("37;2") # normales Haus (dunkelgrün)
    when 0x0A then textcolor("31;2") # Herberge
    when 0x0B then textcolor("34;1") # Wegweiser
    when 0x0C then textcolor("33;1") # Heiler
    when 0x0D then textcolor("36;1") # Händler (Krämer)
    when 0x0E then textcolor("33;2") # Palisade
    when 0x0F then textcolor("37;2") # normales Haus (weiß)
    else           textcolor("37;1") # unbekannt
      
    end
    printf "%02x", tile
    if spid == 0
      printf " "
    else
      textcolor("31;1")
      printf "%01d", spid
    end
  end
  puts
end
