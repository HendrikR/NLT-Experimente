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
    case(@monat)
    when 0; "NL"
    when 1; "PRA"
    when 2; "RON"
    when 3; "EFF"
    when 4; "TRA"
    when 5; "BOR"
    when 6; "HES"
    when 7; "FIR"
    when 8; "TSA"
    when 9; "PHE"
    when 10; "PER"
    when 11; "ING"
    when 12; "RAH"
    else "KAPUTT"
    end
  end
  def to_s
    sprintf("Es ist %s, der %d. %s %d nach Hal, %02d:%02d\n",
            wochentag_s, @tag, monat_s, @jahr, @stunde, @minute)
  end
end

class Chunk_CHAR < Chunk
  attr_accessor :name, :typus
  def read_data
    @portrait = @data[4..5].unpack("S<")[0]
    @oldname  = @data[6..21].unpack("a*")[0]
    @name     = @data[22..37].unpack("a*")[0]
    @typus    = @data[39].unpack("C")[0]
    @sex      = @data[40].unpack("C")[0]
    @stufe    = @data[45].unpack("C")[0]
  end
  def typus_s
    case(@typus)
    when 1;  @sex==0 ? "Gaukler"   : "Gauklerin"
    when 2;  @sex==0 ? "Jäger"     : "Jägerin"
    when 3;  @sex==0 ? "Krieger"   : "Kriegerin"
    when 4;  @sex==0 ? "Streuner"  : "Streunerin"
    when 5;  @sex==0 ? "Thorwaler" : "Thorwalerin"
    when 6;  @sex==0 ? "Zwerg"     : "Zwergin"
    when 7;  @sex==0 ? "Hexer"     : "Hexe"
    when 8;  @sex==0 ? "Druide"    : "Druidin"
    when 9;  @sex==0 ? "Magier"    : "Magierin"
    when 10; @sex==0 ? "Auelf"     : "Auelfe"  
    when 11; @sex==0 ? "Firnelf"   : "Firnelfe"
    when 12; @sex==0 ? "Waldelf"   : "Waldelfe"
    else @typus.to_s;
    end
  end
  def to_s
    sprintf("%s, %s der %d-ten Stufe\n",
            @name, typus_s, @stufe)
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
    if range.class == Fixnum then range = range..range; end
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
    #str += @state.inject(""){|istr,(key,val)|
    #  istr += key + " = " + val.to_s + "\t"
    #}
    str += @allstates.select{|key,val| val != 0}.to_s
    return str
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


chunks.select{|c| c.type == "PLAY"}.each { |x| puts x }

