#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Monster-Viewer für DSA2/RoA2: Sternenschweif (MONSTER.DAT, MONNAMES.LTX)

class Monster
  attr_accessor :id, :sprite_id, :name
  attr_accessor :MU, :KL, :IN, :CH, :FF, :GE, :KK
  attr_accessor :LE, :AE, :MR, :RS, :BP
  attr_accessor :AT_num, :AT, :PA, :TP1, :TP2, :TPPfeil, :TPWurf, :NumPfeil, :NumWurf
  attr_accessor :AP, :Stufe, :Magietyp, :ProfanImmun, :Groesse, :IsAnimal, :LE_Flucht
  attr_accessor :Flags
end

# Funktion zum Schreiben der Singular-Form eines Namens im Singular/Plural-Format
def name_s(name)
  arr = name.split('.')
  if arr.size == 1 then arr[0]
  else arr[0]+arr[1]; end
end

def wuerfel_to_str(wdata)
  wnum = (wdata[1] & 0xF0) >> 4
  wtyp = (wdata[1] & 0x0F)
  wadd = wdata[0]
  case(wtyp)
  when 1 then wtyp = 6
  when 2 then wtyp = 20
  when 3 then wtyp = 3
  when 4 then wtyp = 4
  when 5 then wtyp = 100
  else wtyp = -1
  end
  if wnum == 0
    return wadd.to_s
  else
    #return wnum.to_s+ "W"+ wtyp.to_s+ "+"+ wadd.to_s
    return (wnum+wadd).to_s + "-" + (wnum*wtyp + wadd).to_s
  end
end

# Monster-Liste laden
f_name = File.open("MONNAMES.LTX", "rb:CP850:utf-8")
f_data = File.open("MONSTER.DAT", "rb")
monsters = []
index = 0


monnames = []
f_name.each("\0"){|n| monnames << n}

until monnames.empty?
  m = Monster.new
  m.name      = name_s(monnames.shift)
  m.id        = f_data.read(1).unpack("C")[0]
  m.sprite_id = f_data.read(1).unpack("C")[0]

  m.RS        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.MU        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.KL        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.CH        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.FF        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.GE        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.IN        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.KK        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.LE        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.AE        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.MR        = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.AP        = f_data.read(1).unpack("C")[0]
  m.AT_num    = f_data.read(1).unpack("C")[0]
  m.AT        = f_data.read(1).unpack("C")[0]
  m.PA        = f_data.read(1).unpack("C")[0]
  m.TP1       = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.TP2       = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.BP        = f_data.read(1).unpack("C")[0]
  m.ProfanImmun    = f_data.read(1).unpack("C")[0]
  m.Magietyp  = f_data.read(1).unpack("C")[0]
  m.Stufe     = f_data.read(1).unpack("C")[0]
  m.Groesse   = f_data.read(1).unpack("C")[0]
  m.IsAnimal  = f_data.read(1).unpack("C")[0]
  m.NumPfeil  = f_data.read(2).unpack("S")[0]
  m.TPPfeil   = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.NumWurf   = f_data.read(2).unpack("S")[0]
  m.TPWurf    = wuerfel_to_str(f_data.read(2).unpack("cC"))
  m.LE_Flucht = f_data.read(1).unpack("C")[0]
  # Empfindlichkeiten / Resistenzen gegen bestimmte Waffen?
  # vermutlich ist 1:Empfindlichkeit gegen Feuer, 2:Unempfindlich gegen Stichwaffen
  m.Flags = f_data.read(1).unpack("C")[0]
  monsters << m
  index+= 1
  public def sizeclass
    case(@Groesse)
    when 1 then "winzig"
    when 2 then "klein"
    when 3 then "normal"
    when 4 then "groß"
    when 5 then "riesig"
    else        "?????????????????????"
    end
  end
end
monsters.shift # Das Dummy-Monster darf nicht mitmachen. Oooh.
f_name.close
f_data.close

for m in monsters
  #if m.IsAnimal == 0 then next; end # Gib nur die Tiere aus
  print "Monster ##{m.id}[sprite:#{m.sprite_id}]: #{m.name} Stufe #{m.Stufe}"
  print " (Größe: #{m.sizeclass()})" + (m.Magietyp!=0xFF ? ", Magietyp #{m.Magietyp}":"") + (m.IsAnimal != 0 ? " Tier":"") + (m.ProfanImmun!=0 ? ", nur magisch verletzbar":"") + (m.AT_num>1 ? ", #{m.AT_num} Angriffe":"")
  puts ""
  print "  MU #{m.MU}  KL #{m.KL}  IN #{m.IN}  CH #{m.CH}  FF #{m.FF}  GE #{m.GE}  KK #{m.KK}"
  print "  |  LE #{m.LE}  AE #{m.AE}  RS #{m.RS}, MR #{m.MR}, BP #{m.BP}"
  puts ""
  print "  Gibt #{m.AP} AP, Flucht ab #{m.LE_Flucht} LE.   Flags: #{m.Flags}. "
  print "  AT/PA #{m.AT}/#{m.PA}, #{m.TP1}"+ (m.AT_num>1 ? " / #{m.TP2}" :"") + " TP "
  print ", #{m.NumPfeil} Schuss á #{m.TPPfeil} TP" unless m.NumPfeil == 0
  print ", #{m.NumWurf} Wurf á #{m.TPWurf} TP"     unless m.NumWurf  == 0
  puts ""
end
