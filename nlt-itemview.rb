#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Itemviewer für DSA2/RoA2: Sternenschweif (ITEMS.DAT)

# Insgesamt gibt es 352 Items, davon 84 Waffen und 36 Rüstungsteile.
class Item
  attr_accessor :name, :itemcode, :typ, :typ2, :subtyp, :gewicht, :icon, :preis, :magic, :i_entry, :unk1, :unk2, :unk3
  def name_s
    arr = @name.split('.')
    if arr.size == 1 then arr[0]
    else arr[0]+arr[1]; end
  end
  def typ_s
    str=""
    if (typ & 0x01 != 0) then str+="rst"; end # Rüstung
    if (typ & 0x02 != 0) then str+="waf"; end # Waffe
    if (typ & 0x04 != 0) then str+="use"; end # Benutzbar
    if (typ & 0x08 != 0) then str+="ess"; end # Nahrungsmittel
    if (typ & 0x10 != 0) then str+="stk"; end # Stapelbar
    if (typ & 0x20 != 0) then str+="krt"; end # Kraut/Elixir
    if (typ & 0x40 != 0) then str+="prs"; end # Persönlicher Gegenstand
    if (typ & 0x80 != 0) then str+="oth"; end # Rest?
    return str
  end
  def typ2_s
    str=""
    if (typ2 & 0x01 != 0) then str+="Gürtel"; end
    if (typ2 & 0x02 != 0) then str+="Fingerring"; end
    if (typ2 & 0x04 != 0) then str+="Armring"; end
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
      when 0x00; "getränk"
      when 0x01; "essen"
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
end

f_data = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.DAT", "rb")
f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.LTX", "rb")
f_entry= File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/I_ENTRY.DAT", "rb")
puts f_entry.size

itemlist = []
f_data.read(2)
#f_data.read(14) # Dummy-Item
while(data = f_data.read(14))
  break if data.size < 14
  break if f_name.eof?
  data = data.bytes
  name = ""
  while((c = f_name.read(1)) != "\0") do name+=c; end
  i = Item.new
  i.name = name
  i.i_entry  = f_entry.readbyte
  
  i.typ      = data[0x00]
  i.typ2     = data[0x01]
  i.subtyp   = data[0x02]
  i.icon     = data[0x03] # Bild-Index oder ähnlich?
  i.gewicht  = data[0x04]
  i.unk1     = data[0x05] # Immer 0, außer bei einigen Rüstungen und der Sumpfrantze
  i.preis    = data[0x08] * (data[0x07] << 8 | data[0x06])
  i.unk2     = data[0x09] # Für die meisten Gegenstände 0, für einige Gegenstände Werte im niedrigen 2-stelligen Hex-Bereich (0x0?, 0x1?)
  i.magic    = data[0x0A]
  i.unk3     = data[0x0B] # Flag/Enum, ist entweder 0,1 oder 2. 2 könnte "benutzbar" sein oder so, 1 ist seltsam.
  i.itemcode = data[0x0C] << 8 | data[0x0D]#ja
  itemlist << i
end

itemlist.each do |item|
  printf("%04x, %s, %02x\n", item.itemcode, item.name_s, item.i_entry)
end
