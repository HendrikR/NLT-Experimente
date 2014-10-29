#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Itemviewer für DSA2/RoA2: Sternenschweif (ITEMS.DAT)


# Insgesamt gibt es 352 Items, davon 84 Waffen und 36 Rüstungsteile.
class Item
  attr_accessor :index, :name, :icon, :typ, :typ2, :subtyp, :gewicht, :fk_index, :preis, :magic, :i_entry, :haeufigkeit, :genus
  def name_s
    arr = @name.split('.')
    if arr.size == 1 then arr[0]
    else arr[0]+arr[1]; end
  end
  def typ_s
    str=""
    if (typ & 0x01 != 0) then str+="Rüstung"; end # Rüstung
    if (typ & 0x02 != 0) then str+="Waffe"; end # Waffe
    if (typ & 0x04 != 0) then str+="benutzbar"; end # Benutzbar
    if (typ & 0x08 != 0) then str+="Nahrung"; end # Nahrungsmittel
    if (typ & 0x10 != 0) then str+="stapelbar"; end # Stapelbar
    if (typ & 0x20 != 0) then str+="Kraut/Elixir"; end # Kraut/Elixir
    if (typ & 0x40 != 0) then str+="persönlich"; end # Persönlicher Gegenstand
    if (typ & 0x80 != 0) then str+="???"; end # Rest?
    return str
  end
  def typ2_s
    str=""
    if (typ2 & 0x01 != 0) then str+="Gürtel"; end
    if (typ2 & 0x02 != 0) then str+="Fingerring"; end
    if (typ2 & 0x04 != 0) then str+="Armreif"; end
    if (typ2 & 0x08 != 0) then str+="Halskette"; end
    if (typ2 & 0x10 != 0) then str+="Übermantel"; end
    if (typ2 & 0x20 != 0) then str+="Stirnreif"; end
    if (typ2 & 0x40 != 0) then str+="Bein-/Armschienen"; end
    if (typ2 & 0x80 != 0) then str+="Unbiskant"; end
    return str
  end
  def subtyp_s
    if    (typ & 0x01 != 0)  #Rüstung
      case(subtyp)
      when 0x00; "Kopf"
      when 0x01; "Arme"
      when 0x0A; "Torso"
      when 0x05; "Beine"
      when 0x0E; "Füße"
      when 0x09; "Schildhand"
      else       "unbekannt:"+subtyp.to_s
      end
    elsif (typ & 0x02 != 0)  #Waffe
      case(subtyp)
      when 0x00; "Muni/nichts"
      when 0x01; "Hiebwaffe"
      when 0x02; "Stichwaffe"
      when 0x03; "Schwerter"
      when 0x04; "Äxte"
      when 0x05; "Speere"
      when 0x06; "Zweihänder"
      when 0x07; "Schusswaffen"
      when 0x08; "Wurfwaffen"
      else       "unbekannt:"+subtyp.to_s
      end
    elsif (typ & 0x08 != 0)  #Nahrungsmittel
      case(subtyp)
      when 0x00; "Getränk"
      when 0x01; "Essen"
      else       "unbekannt:"+subtyp.to_s
      end
    elsif (typ & 0x20 != 0)  #Kraut/Elixier
      case(subtyp)
      when 0x01; "Elixir"
      else       "unbekannt:"+subtyp.to_s
      end
    else
      "unbekannt:"+subtyp.to_s
    end
  end
  def genus_s
    case(genus)
    when 0; "Der"
    when 1; "Die"
    when 2; "Das"
    else    "Error"
    end
  end
  def read(index, name, data, diary_entry)
    @i_entry = diary_entry
    @name    = name
    @index       = index
    @icon        = data[0x00] | data[0x01] << 8
    @typ         = data[0x02]
    @typ2        = data[0x03]
    @subtyp      = data[0x04]
    @fk_index    = data[0x05] # Index in eine andere Tabelle (Rüstungs- oder Waffenwerte, ...)
    @gewicht     = data[0x06] | (data[0x07] << 8)
    @preis       = data[0x0A] * (data[0x09] << 8 | data[0x08])
    @haeufigkeit = data[0x0B] # Siehe [[http://www.crystals-dsa-foren.de/showthread.php?tid=700&pid=125835#pid125835]]
    @magic       = data[0x0C]
    @genus       = data[0x0D] # Grammatikalisches Geschlecht (im Deutschen): 0=m, 1=f, 2=n
  end
  def write()
  end
  def fk_object()
    # Read extra info from .EXE, if necessary
    if    typ & 0x01 != 0
      return $armor_list[fk_index]
    elsif typ & 0x02 != 0
      return $weapon_list[fk_index]
    elsif typ & 0x20 != 0
      return $recipe_list[fk_index]
    end
  end
end

def read_items
  f_data = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.DAT", "rb")
  f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.LTX", "rb")
  f_entry= File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/I_ENTRY.DAT", "rb")
  f_exe  = File.open("/home/hendrik/sandkasten/dosbox/crpg/RoA2/STAR.EXE", "rb")
  exe_version = get_version(f_exe)
  $armor_list  = read_armor_list(f_exe, exe_version)
  $weapon_list = read_weapon_list(f_exe, exe_version)
  $recipe_list = read_recipe_list(f_exe, exe_version)
  
  itemlist = []
  index = 0
  while(data = f_data.read(14))
    break if data.size < 14
    break if f_name.eof?
    data = data.bytes
    # read name and diary entry flag
    name = ""
    while((c = f_name.read(1)) != "\0") do name+=c; end
    diary_entry = 0
    if not f_entry.eof?
      diary_entry  = f_entry.readbyte # Wenn i_entry==1, wird der Fund im Tagebuch vermerkt.
    end
    # read the rest
    i = Item.new
    i.read(index, name, data, diary_entry)
    itemlist << i
    index+= 1
  end
  itemlist.pop # Das letzte Item, "Dukaten", hat keinen sinnvollen Eintrag.
  return itemlist
end

def read_all
end


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

# Item-Blacklisten nach Charaktertyp
TYPUS = ["Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]
def read_item_blacklist(file, version)
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

def read_armor_list(file, version)
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
def read_weapon_list(file, version)
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

class Recipe
  attr_accessor :id_recipe, :ingredients, :id_result, :cost_ae, :cost_TH, :cost_TM
  def initialize(data)
    @id_recipe = data[0..1].unpack("S")[0]
    @ingredients   = []
    for i in 0..9
      zutat = data[(2+2*i)..(3+2*i)].unpack("S")[0]
      @ingredients << zutat unless zutat == 0xFFFF
    end
    @ingredients = @ingredients.inject(Hash.new(0)) {|h, item| h.tap { h[item] += 1 }}
    @id_result = data[22..23].unpack("S")[0]
    @cost_ae = data[24..25].unpack("S")[0]
    @cost_TM = data[26].unpack("C")[0] # Unbekannt. Brauzeit(Minuten)?
    @cost_TH = data[27].unpack("C")[0]
  end
  def to_s
    ret  = $items[@id_recipe] + ": "
    @ingredients.each_pair{|z,num| ret += "#{num} #{$items[z]}, "}
    ret += "#{@cost_ae} AE und %02d Stunden " % [@cost_TH]
    ret += "ergibt #{$items[@id_result]} [#{@cost_TM}]"
    ret += "\n"
    return ret
  end
end
def read_recipe_list(file, version)
  offsets = {:o100 => 0x26F66, :c100 => 0x28818, :c102 => 0x2881A, :c200 => 0x26676}
  file.seek(offsets[version])
  
  list = []
  for i in 0...14
    list[i] = Recipe.new(file.read(28))
  end
  return list
end
