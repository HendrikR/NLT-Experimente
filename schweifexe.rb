# -*- coding: utf-8 -*-

require_relative "_common.rb"

=begin
Liste von Offsets in der Schweif.exe (Version C1.02)
rezept_list    offsets = {:start => 0x2881A, :len => 14*28, :end => 0x289A2}
something1     offsets = {:start => 0x289A2, :len => ???,   :end => 0x28A80}
?spell_list    offsets = {:start => 0x28A80, :len => 86*8,  :end => 0x28D30}
something3     offsets = {:start => 0x28D30, :len => ???,   :end => 0x2925D}
something*     offsets = {:start => 0x2925D, :len => ???,   :end => 0x299A3}
item_blacklist offsets = {:start => 0x299A3, :len => var  , :end => 0x29D9B}
something      offsets = {:start => 0x29D9B, :len => var  , :end => 0x29E2B}
weapon_list    offsets = {:start => 0x29E2B, :len => 77*8 , :end => 0x2A093}
#dummy-waffe 8 bytes
armor_list     offsets = {:start => 0x2A09B, :len => 27*2 , :end => 0x2A0D1}
startinv       offsets = {:start => 0x2C8C6, :len => 12*4 , :end => 0x2C930}
=end

# Ermittle die Version der .exe
def get_version(file_exe)
  def readv(file, ofs); file.seek(ofs); file.read(5); end
  if    readv(file_exe, 0x2A96D) == "C1.02" then return :c102 # Deutsch
  elsif readv(file_exe, 0x28775) == "C2.00" then return :c200 # Englisch
  #elsif readv(file_exe, ???) == "O1.00" then return :o100 # Deutsch
  #elsif readv(file_exe, ???) == "C1.00" then return :c100 # Deutsch
  else  raise "Fehler: Unbekannte Sternenschweif-Version"
  end
end

def item_something(file, version)
  #offsets = {:c102 => 0x28D30}

  #offsets = {:c102 => 0x29989} # Schuhwerk, Münzen, Dietriche, Bonbons, Lobpreisungen. Hmm - alles Mehrzahl?
  #offsets = {:c102 => 0x29945} # viele 0en, dann Süßkram, Gifte, Öle, Lobpreisungen, Rüst-Zeug, Schmuck. Hm.
  offsets = {:c102 => 0x292FD} # ID=06-45. Div. Waffen, Kletterkram, Schuppenpanzer, Decke, Schaufel.
  file.seek(offsets[version])
  

  list = []

  loop do
    id = file.read(2).unpack("S<")[0]
    break if id == 0xFFFF
    list << id
  end
  return list
end


# Item-Blacklisten nach Charaktertyp
# TODO: Direkt vor den Item-Blacklisten sind noch 2 andere, merkwürdige Listen, die genauso aufgebaut sind.
# Die 1. Liste enthält die meisten Flüssigkeiten (Gifte, Öl, Wein, Gegengift); dazu 3 Rüstungen (Leder, Kette, Platte), Schmuckhalsbänder, Lobpreisungen, Pergamente.
# Die 2. Liste enthält: Dietrich, div. Schuhwerk, Bonbons, Lobpreisungen, div. Juwelen und Münzen (grün, rot, bunt).
# Denkbar, dass diese Indices in andere Listen (Kämpfe?) zeigen -- aber angesichts der Aufzählungen z.B. von Gift oder Schmuck (mit unzusammenhängenden Itemnummern) können das eigentlich nur Items sein.
def item_blacklist(file, version)
  offsets = {:o100 => 0x280EF, :c100 => 0x299A1, :c102 => 0x299A3, :c200 => 0x277FF}
  file.seek(offsets[version])

  list = {}

  for i in 0...12
    list[TYPUS[i]] = []
    loop do
      id = file.read(2).unpack("S<")[0]
      break if id == 0xFFFF
      #printf("- %s [%04x]\n", ITEMNAMES[id], id)
      list[TYPUS[i]] << id
    end
  end
  return list
end


class Armor
  attr_accessor :id, :rs, :be
  def initialize(id, data)
    @id = id
    @rs, @be = data.unpack("CC")
  end

  def to_s
    "Rüstung #%02x:\tRS #{@rs}, BE #{@be}\n" % @id
  end
end
def armor_list(file, version)
  offsets = {:o100 => 0x287E7, :c100 => 0x2A099, :c102 => 0x2A09B, :c200 => 0x27EF7}
  file.seek(offsets[version])

  list = []
  for i in 0...27 do
    a = Armor.new(i, file.read(2))
    break if a.rs == 0xFF && a.be == 0xFF
    list << a
  end
  #p file.tell.to_s(16)
  return list
end

class Weapon
  attr_accessor :id, :tp_w6, :tp_add, :kk_zuschlag, :bf, :unk1, :mod_at, :mod_pa, :anim_type
  def initialize(id, data)
    @id          = id
    @tp_w6       = data[0].unpack("C")[0]
    @tp_add      = data[1].unpack("c")[0]
    @kk_zuschlag = data[2].unpack("C")[0]
    @bf          = data[3].unpack("c")[0]
    @unk1        = data[4].unpack("C")[0] # Scheint ein weiterer Fremdschlüssel für Fernwaffen zu sein (Entfernungstabelle?). Für den Schneidzahn allerdings ist der Wert 0xff.
    @mod_at      = data[5].unpack("c")[0]
    @mod_pa      = data[6].unpack("c")[0]
    @anim_type   = data[7].unpack("C")[0] # Waffengattung (für die Animation auf dem Kampfbildschirm)
    # Werte von 0 bis 6.
    # 0: Messer, Dolch, Obsidiandolch, Wolfsmesser, Asthenilmesser, Asthenildolch {kleine Stichwaffen}
    # 1: Knüppel, Morgenstern, Pike, Streitkolben, Kampfstab, Peitsche, Kriegshammer, Hellebarde, Dreschflegel, Ochsenherde, Rabenschnabel, Brabakbengel, Hexenbesen, Streitkolben* {Hieb-Waffen}
    # 2: alles andere {Schwerter und lange Stichwaffen}
    # 3: Kriegsbeil, Streitaxt, Kriegsbeil, Orknase, Orknase*, Orkbeil, Gruufhai {Äxte}
    # 4: Kurzbogen, Armbrust, Langbogen, Pfeile/Bolzen, Bogen des Artherion, Schwere Armbrust {Schusswaffen}
    # 5: Wurfbeil, Wurfstern, Wurfaxt, Wurfmesser, ???, Schneidzahn, Wurfdolch*, Wurfaxt (golden), Borndorn {Wurfwaffen}
    # 6: Speer, Speer*
  end
  def to_s
    "Waffe #%02x: #{@tp_w6}W+#{@tp_add} TP, KK-Zuschlag #{@kk_zuschlag},\tAT/PA % 2d/% 2d, BF #{@bf},\tdist: %x, anim %x" \
    % [@id, @mod_at, @mod_pa, @unk1, @anim_type]
  end
end
def weapon_list(file, version)
  offsets = {:o100 => 0x28577, :c100 => 0x29E29, :c102 => 0x29E2B, :c200 => 0x27C87}
  file.seek(offsets[version])

  list = []
  for i in 0...77
    data = file.read(8)
    w = Weapon.new(i, data)
    list[i] = w
  end
  return list
end


class Rezept
  attr_accessor :id_recipe, :zutaten, :id_result, :kosten_ae, :kosten_TH, :kosten_TM
  def initialize(data)
    @id_recipe = data[0..1].unpack("S")[0]
    @zutaten   = []
    for i in 0..9
      zutat = data[(2+2*i)..(3+2*i)].unpack("S")[0]
      @zutaten << zutat unless zutat == 0xFFFF
    end
    @zutaten = @zutaten.inject(Hash.new(0)) {|h, item| h.tap { h[item] += 1 }}
    @id_result = data[22..23].unpack("S")[0]
    @kosten_ae = data[24..25].unpack("S")[0]
    @kosten_TM = data[26].unpack("C")[0] # Unbekannt. Brauzeit(Minuten)?
    @kosten_TH = data[27].unpack("C")[0]
  end
  def to_s
    ret  = ITEMNAMES[@id_recipe] + ": "
    @zutaten.each_pair{|z,num| ret += "#{num} #{ITEMNAMES[z]}, "}
    ret += "#{@kosten_ae} AE und %02d Stunden " % [@kosten_TH]
    ret += "ergibt #{ITEMNAMES[@id_result]} [#{@kosten_TM}]"
    ret += "\n"
    return ret
  end
end
def rezept_list(file, version)
  offsets = {:o100 => 0x26F66, :c100 => 0x28818, :c102 => 0x2881A, :c200 => 0x26676}
  file.seek(offsets[version])
  
  list = []
  for i in 0...14
    list[i] = Rezept.new(file.read(28))
  end
  return list
end


def spell_list(file, version)
  # hat vermutlich irgendwas mit Zaubersprüchen zu tun: es gibt genau 86 Einträge à 8 Bytes.
  # Die letzten 4 Bytes sind immer 0, Byte 3 immer 36, Byte 2 wächst von 12 bis 47
  # - Zusammen ergeben die 4 ersten Bytes eine monoton steigende Folge.
  #   x steigt immer um je 5 bis zu einem bestimmten Wert, dann wird x 'rückgesetzt' auf eine kleine Zahl und zugleich y um 8,9 oder 10 erhöht.
  # - sieht ein wenig nach Koordinaten (y,x) aus, ergibt aber dargestellt wenig Sinn.
  #   Die Darstellung ergibt zwar eine Tabelle, aber die Spalten sind vertikal nicht aneinander ausgerichtet.
  #   Außerdem wechselt die Spalte oft mitten in der Gruppe.
  # - Mit den Zaubergruppen stimmt es auch nicht überein
  # - Die Zauber-Sounds scheinen auch nach Gruppe gewählt zu sein, das ist es wohl auch nicht.
  # - ...
  offsets = {:c102 => 0x28A80 }
  file.seek(offsets[version])
  list = []
  #puts "<svg xmlns=\"http://www.w3.org/2000/svg\"><g transform='scale(0.6)'>"
  for i in 0...86
    data = file.read(8).unpack("S<CCL<")
    #puts SPELL[i].ljust(30) + data.to_s #if data[2] != 36
    #puts "<text x='#{20*data[1]}' y='#{5*data[0]-100}'>#{SPELL[i]}</text>"
  end
  #puts "</g></svg>"
  return list
end

def start_inventory(file, version)
  offsets = {:c102 => 0x2C8C6 }
  file.seek(offsets[version])
  typus2 = ["Allgemein"]+TYPUS
  for i in 0...13
    if i == 0 then count = 5
    else           count = 4; end
    items = file.read(count*2).unpack("S<*")
    print typus2[i] + ": "
    items.each{|x| print " " + ITEMNAMES[x] unless x==0xFFFF}
    puts
  end
end

def mohr(file, version)
  offsets = {:c102 => 0x2A0D1 }
  file.seek(offsets[version])
  count = 12
  items = file.read(count*2).unpack("S<*")
  items.each{|x| print " " + ITEMNAMES[x] unless x==0xFFFF}
  puts
end

file_exe = File.open(ARGV[0])
version = get_version(file_exe)
#puts "Sternenschweif .EXE Version #{version}"
#spell_list(file_exe, version)
#start_inventory(file_exe, version)
#puts armor_list(file_exe, version)
#puts weapon_list(file_exe, version)
#puts rezept_list(file_exe, version)
#mohr(file_exe,version)

=begin
item_blacklist = item_blacklist(file_exe, version)
item_blacklist.each_pair do |key,list|
  puts "    #### #{key}:"
  for id in list
    printf("- %s [%04x]\n", ITEMNAMES[id], id)
  end
end
=end

item_something(file_exe, version).each do |id|
  printf("- %s [%04x]\n", SPELL[id], id)
end
file_exe.close


=begin

=end
