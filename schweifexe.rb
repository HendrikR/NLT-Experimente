# -*- coding: utf-8 -*-

# Ermittle die Version der .exe
def get_version(file_exe)
  file_exe.seek(0x28775)
  version = file_exe.read(5)
  if    version == "O1.00" then return :o100 # Deutsch
  elsif version == "C1.00" then return :c100 # Deutsch
  elsif version == "C1.02" then return :c102 # Deutsch
  elsif version == "C2.00" then return :c200 # Englisch
  else  raise "Fehler: Unbekannte Sternenschweif-Version »#{version}«"
  end
end

# Hilfsfunktionen
def name_s(name)
  arr = name.split('.')
  if arr.size == 1 then arr[0]
    else arr[0]+arr[1]; end
end

def read_items()
  # Namen der Items einlesen
  f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.LTX", "rb", :encoding => "CP437")
  
  $items = f_name.read.split("\0")
  $items = $items.inject([]) {|arr,i| arr << name_s(i)}
  f_name.close
end
  
# Waffen-Blacklisten nach Charaktertyp
TYPUS = ["Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]
def weapon_blacklist(file, version)
  offsets = {:o100 => 0x280EF, :c100 => 0x299A1, :c102 => 0x299A3, :c200 => 0x277FF}
  file.seek(offsets[version])

  list = {}

  for i in 0...12
    list[TYPUS[i]] = []
    loop do
      id = file.read(2).unpack("S<")[0]
      break if id == 0xFFFF
      #printf("- %s [%04x]\n", $items[id], id)
      list[TYPUS[i]] << id
    end
  end
  return list
end


class Armor
  attr_accessor :rs, :be
end
def armor_list(file, version)
  offsets = {:o100 => 0x287E7, :c100 => 0x2A099, :c102 => 0x2A09B, :c200 => 0x27EF7}
  file.seek(offsets[version])

  list = []
  loop do
    a = Armor.new
    a.rs = file.read(1).unpack("C")[0]
    a.be = file.read(1).unpack("C")[0]
    break if a.rs == 0xFF && a.be == 0xFF
    list << a
  end
  return list
end

class Weapon
  attr_accessor :id, :tp_w6, :tp_add, :kk_zuschlag, :bf, :unk1, :mod_at, :mod_pa, :unk2
  def initialize(id, data)
    @id          = id
    @tp_w6       = data[0].unpack("C")[0]
    @tp_add      = data[1].unpack("c")[0]
    @kk_zuschlag = data[2].unpack("C")[0]
    @bf          = data[3].unpack("c")[0]
    @unk1        = data[4].unpack("C")[0] # Scheint ein weiterer Fremdschlüssel für Fernwaffen zu sein (Entfernungstabelle?). Für den Schneidzahn allerdings ist der Wert 0xff.
    @mod_at      = data[5].unpack("c")[0]
    @mod_pa      = data[6].unpack("c")[0]
    @unk2        = data[7].unpack("C")[0] # Waffengattung (evtl. für die Auswahl der Animation auf dem Kampfbildschirm?)
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
    "Waffe #%02x: #{@tp_w6}W+#{@tp_add} TP, KK-Zuschlag #{@kk_zuschlag},\tAT/PA % 2d/% 2d, BF #{@bf},\tunk: %x, %x" \
    % [@id, @mod_at, @mod_pa, @unk1, @unk2]
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
    ret  = $items[@id_recipe] + ": "
    @zutaten.each_pair{|z,num| ret += "#{num} #{$items[z]}, "}
    ret += "#{@kosten_ae} AE und %02d Stunden " % [@kosten_TH]
    ret += "ergibt #{$items[@id_result]} [#{@kosten_TM}]"
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


file_exe = File.open(ARGV[0])
read_items()
version = get_version(file_exe)
=begin
weapon_blacklist = weapon_blacklist(file_exe, version)
weapon_blacklist.each_pair do |key,list|
  puts "    #### #{key}:"
  for id in list
    printf("- %s [%04x]\n", $items[id], id)
  end
end

armor_list = armor_list(file_exe, version)
armor_list.each_with_index do |a,i|
  puts "Rüstung ##{i}: RS #{a.rs} BE #{a.be}"
end
=end

weapon_list = weapon_list(file_exe, version)
weapon_list.each_with_index do |w,i|
  puts w if w.unk2 == 2
end

=begin
rezept_list = rezept_list(file_exe, version)
rezept_list.each_with_index do |r,i|
  puts r
end
=end
file_exe.close
