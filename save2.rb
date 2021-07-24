# coding: utf-8

# Chunk-Typen
# - CHAR: Daten für die einzelnen Charaktere ("Heldenbriefe")
# - PART: Vermutlich Aufteilung der Gruppe: Es gibt 6 dieser Blöcke.
#   - Platz für 7 DWORDS, die wohl angeben, wer in dieser Party in welchem Slot sitzt
#   - Weitere Daten, was auch immer
# - XDIA: 130 Bytes.
#   + Booleans, gibt an, welche Themen aus TOPICS.TOP man (global) kennt.
#   "Global" bedeutet: Man kann /jeden/ danach fragen. Aktivieren aller Themen
#   erzeugt einen kaputten, weil übervollen Dialogschirm.
# - TIME: Ingame-Zeit
#   + Format siehe oben.
# - AMAP: Enthält nur ein WORD, vermutlich irgendwelche Flags bzgl. Automap.
# - GLOB:
#   - Unbekannt, manchmal stehen Charakternamen da drin.
# - RUNV:
#   - ???
# - MONS: 124 Bytes
#   - jeweils 1 Bool, ob man diesen Gegnertyp schon bekämpft hat (wegen Erst-AP)
# - PLAY: 651 Bytes.
#   - Sammlung von Spielstatus-Variablen. Jede Menge Arbeit, die rauszutüfteln.
# - LOCS: 307 Bytes.
#   - Vermutlich 1 Byte + 153 WORD-Flags, für erkundete Strecken auf der Landkarte.
# - TEMP: Platz für eine temporäre Datei, z.B. Automap-Status, Spieler-Notizen in Levels etc.
#   + Gefolgt von einem 0-terminierten Dateinamen und den Daten.

require './_common.rb'

class Chunk
  attr_accessor :type, :length, :data, :pos
  def initialize(file, pos)
    file.seek(pos)
    @pos    = pos
    @type   = file.read(4)
    @length = file.read(2).unpack("S<")[0]
    if @length == 0xFFFF
      @header_len = 10
      @length = file.read(4).unpack("L<")[0]
    else
      @header_len = 6
    end
    @data   = file.read(@length)
    read_data
  end
  def read_data; end
  def nextpos; @pos + @header_len + @length; end
  def to_s
    "unprocessed "+ @type +" Chunk\n"
  end
end

class Chunk_TIME < Chunk
  attr_accessor :jahr, :monat, :tag, :wochentag, :stunde, :minute, :ticks
  def read_data
    data = @data.unpack("L<CCCCCS<")
    @ticks = data[0]
    ticksprosekunde = 0x10000 / (12*3600.0)
    sekundenseit0uhr = @ticks / ticksprosekunde
    @stunde = sekundenseit0uhr / 3600
    @minute = (sekundenseit0uhr % 3600) / 60
    @wochentag = data[2]
    @tag = data[3]
    @monat = data[4]
    @jahr = data[5]
  end

  def wochentag_s
    case(@wochentag)
    when 0; "Rohalstag"
    when 1; "Feuertag"
    when 2; "Wassertag"
    when 3; "Windstag"
    when 4; "Erdstag"
    when 5; "Markttag"
    when 6; "Praiostag"
    else    "KAPUTT"
    end
  end

  def monat_s
    return "Ungültiger Monat #{@monat}" if @monat < 0 or @monat > 12
    return MONTH_NAME[@monat]
  end

  def to_s
    sprintf("Es ist %s, der %d. %s %d nach Hal, %02d:%02d\n",
            wochentag_s, @tag, monat_s, @jahr, @stunde, @minute)
  end
end

EQU_SLOTS = ["Kopf", "Arme", "Reif (r)", "Hand (r)", "Ring (r)", "Hose", "Schenkel", "Gürtel", "Hals", "Mantel", "Torso", "Reif (l)", "Hand (l)", "Ring (l)", "Schuhe"]

class Chunk_CHAR < Chunk
  attr_accessor :name, :typus
  def read_data
    @portrait = @data[0x04..0x05].unpack("S<")[0]
    @oldname  = @data[0x06..0x15].unpack("a*")[0]
    @name     = @data[0x16..0x25].unpack("a*")[0]
    @typus    = @data[0x27].unpack("C")[0]
    @sex      = @data[0x28].unpack("C")[0]
    @stufe    = @data[0x2D].unpack("C")[0]
    @rs, @be  = @data[0x36..0x37].unpack1("S<C")
    num_eig   = @data[0x38].unpack1("C")
    @attribs  = @data[0x3A..0x4E].unpack("C*").each_slice(3).to_a.transpose # normal, current, ??? (immer 0?)
    @atpa_at  = @data[0x6E..0x74].unpack("C*") # at-werte für waffen, nach abzug des RS: faust, hieb, stich, schwert, axt, speer, 2h
    @talente  = @data[0x10E..0x141].unpack("c*")
    @zauber   = @data[0x143..0x198].unpack("c*")
    # 27 Bytes pro Slot. 15 Slots --> 405 Bytes.
    @ausrüst  = @data[0x19C..0x330].unpack("C*")
    # 27 Bytes pro Slot. 16 Slots --> 432 Bytes
    @inv      = @data[0x331..0x4E0].unpack("C*")
  end

  def typus_s
    return "Ungültiger Typus (#{@typus})" if @typus < 1 or @typus > 12
    return "Ungültiges Geschlecht (#{@sex})" if @sex != 0 and @sex != 1
    typename = TYPUS[@typus-1]
    typename += @sex == 0 ? " (M)" : " (F)"
  end

  def to_s
    #"#{@name}, #{typus_s()} der #{@stufe}-ten Stufe\n"
    #tab = {}; @zauber.each_with_index{|v,i| tab[SPELL[i]] = v }
    "#{@name}, %s}\n" % @inv.map{|x| "0x%02X" % x}.join(", ")
  end
end

class Chunk_PART < Chunk
  def read_data
    @slots = @data[0..(7*4)].unpack("L*")
    # Einige der unbekannten Bytes dürften Koordinaten darstellen.
    data = @data[(7*4)..-1].unpack("LLS SSSS CC C*")
    
    @count = data[7]
  end
  def to_s
    str = "#{@count} Slots: "
    6.times{|i| str+= @slots[i].to_s+"|"}
    str += " "+@slots[6].to_s+"\n"
    return str
  end
end

class Chunk_PLAY < Chunk
  attr_accessor :state
  def add(name, range, unpack="C*")
    if range.class == Integer then range = range..range; end
    d = @data[range].unpack(unpack)
    @state[name] = d.one? ? d[0] : d
    range.each{|idx| @allstates.delete(idx) }
  end
  def read_data
    @state = Hash.new
    @allstates = Hash.new
    for i in 0...@data.size do @allstates[i] = @data[i].ord; end
    # All das ist in einem frischen Savegame (EMPTY,START.GAM) gesetzt
    add("init",1); add("init",4); add("init",6); add("init",9); add("init",13..18); add("init",20..22);add("init",208)
    add("?frisch importiert(1)", 19)
    add("?frisch importiert(2)", 249)
    # All das ist nach den Gesprächen mit Elsurion und Alatzer gesetzt, mit unbekanntem Effekt
    add("na=2",51); add("na",111);add("na",113);add("na",114);add("na",117);add("na",153);add("na",253)
    add("mit Elsurion & Alatzer gesprochen", 252)
    # Nach dem nächtlichen Gespräch mit dem Kapuzenheini in der Herberge in Kvirasim
    add("Sternenschweif-Auftrag erhalten", 115); add("Sternenschweif-Auftrag erhalten", 140);
    # Unterstützung für die Rondra-Geweihte.
    # Wenn man sie ihrem Schicksal überlässt, sind beide Flags nicht gesetzt.
    add("Rondra-Geweihte vor Kvirasim",92); add("Rondra-Geweihte vor Kvirasim",95);
    add("mit der Elfe in den Salamandersteinen geredet", 59)
    # Die Begegnungen mit der Elchreiterin setzen keine neue Variable (zu testen: werden alte beeinflusst?)
  end
  def to_s
    #str = "Game state:\n"
    str = ""
    str += @state.map{|key,val|
      key + " = " + val.to_s + "\t"
    }.join
    str += @allstates.select{|key,val| val != 0}.to_s
    return str
  end
end

class Chunk_TEMP < Chunk
  def read_data
    @filename = @data[0..12].unpack("Z*")[0]
    @unk1 = @data[13..13].unpack("C")[0]
    @content = @data[14..-1]
  end
  def to_s
    "Temp file #{@filename} (#{@length-14} bytes): #{@unk1}"
  end
end

class Chunk_GLOB < Chunk
  def read_data
  end
  def to_s
    @data.unpack("C*").to_s
  end
end

chunks = []
f = File.new(ARGV[0])
pos = 0x114 # DESC-Chunk ohne Längenangabe überspringen
while not f.eof?
  f.seek(pos)
  type = f.read(4)
  begin
    c = Object.const_get("Chunk_"+type).new(f,pos)
  rescue NameError
    c = Chunk.new(f,pos)
  end
  pos = c.nextpos
  chunks << c
  #puts "read chunk #{c.type} from %x" % c.pos
end


chunks.select{|c| c.type == "CHAR"}.each { |c| puts c.length + ":  " + c.to_s if c.typus == 3}
