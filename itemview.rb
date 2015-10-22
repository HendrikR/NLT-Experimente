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
end

f_data = File.open("ITEMS.DAT", "rb")
f_name = File.open("ITEMS.LTX", "rb:CP850:utf-8")
f_entry= File.open("I_ENTRY.DAT", "rb")

itemlist = []
itemnames= f_name.read.split("\0")

#f_data.read(2)
#f_data.read(14) # Dummy-Item
index = 0
while(data = f_data.read(14))
  break if data.size < 14
  data = data.bytes
  i = Item.new
  i.name = itemnames.shift
  if not f_entry.eof?
    i.i_entry  = f_entry.readbyte # Wenn i_entry==1, wird der Fund im Tagebuch vermerkt.
  else
    i.i_entry  = 0
  end
  
  i.index       = index
  i.icon        = data[0x00] | data[0x01] << 8
  i.typ         = data[0x02]
  i.typ2        = data[0x03]
  i.subtyp      = data[0x04]
  i.fk_index    = data[0x05] # Index in eine andere Tabelle (Rüstungs- oder Waffenwerte, ...)
  i.gewicht     = data[0x06] | (data[0x07] << 8)
  i.preis       = data[0x0A] * (data[0x09] << 8 | data[0x08])
  i.haeufigkeit = data[0x0B] # Siehe [[http://www.crystals-dsa-foren.de/showthread.php?tid=700&pid=125835#pid125835]]
  i.magic       = data[0x0C]
  i.genus       = data[0x0D] # Grammatikalisches Geschlecht (im Deutschen): 0=m, 1=f, 2=n

  itemlist << i
  index+= 1
end
itemlist.pop # Das letzte Item, "Dukaten", hat keinen sinnvollen Eintrag.

puts "<!DOCTYPE HTML>"
puts "<html><head>"
puts "<title>Liste der Gegenstände für DSA2</title>"
puts "<meta http-equiv='content-type' content='text/html; charset=utf-8' />"
puts "</head><body><table border='1'>"
puts "<tr><th>Index</th><th>Name</th><th>Item-Typ</th><th>Gewicht (U)</th><th>Häufigkeit</th><th>Flags</th><th>Fk_Index</th></tr>"
def d(val)
  puts "<td>#{val.to_s}</td>"
end
itemlist.sort_by{|i| i.fk_index}
itemlist.each do |item|
  if item.typ & 0x02 == 0 then next; end
  printf("%s: %02x\n", item.name_s + (item.magic==1 ? "*" : ""), item.fk_index)
=begin
  puts "<tr>"
  d sprintf("%x", item.index)
  d sprintf("<img src='item-S00I%03d.png' width='32'>", item.icon) + " " +
    item.genus_s + " " + 
    item.name_s
  d item.typ_s+":" + item.typ2_s + "("+item.subtyp_s+")"
  d item.gewicht
  d item.haeufigkeit
  d (item.magic==1 ? "M" : "&nbsp;") + (item.i_entry==1 ? "T" : "&nbsp;")
  d sprintf("%x", item.fk_index)
  puts "</tr>"
=end
end
puts "</table></body></html>"
