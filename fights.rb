#!/usr/bin/ruby
# -*- coding: utf-8 -*-
# Kampf-Viewer für DSA2/RoA2: Sternenschweif (FIGHT.LST, SCENARIO.LST)

# Insgesamt gibt es 352 Items, davon 84 Waffen und 36 Rüstungsteile.
class Fight
  attr_accessor :id, :name, :enemies, :enemy_groups, :players, :loot, :money
  def initialize()
    @enemies = Array.new
    @players = Array.new
    @loot    = Array.new
    @enemy_groups = Array.new
  end
end

class Fighter
  attr_accessor :id, :posx, :posy, :lookat, :when
  attr_accessor :number # To group fighters by ID
end

# Funktion zum Schreiben der Singular-Form eines Namens im Singular/Plural-Format
def name_s(name)
  arr = name.split('.')
  if arr.size == 1 then arr[0]
  else arr[0]+arr[1]; end
end


# Item-Liste laden für die Namen der Beute-Gegenstände
def read_items()
  f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/ITEMS.LTX", "rb")
  
  itemlist = []
  index = 0
  until f_name.eof?
    name = ""
    while((c = f_name.read(1)) != "\0") do name+=c; end
    itemlist << name_s(name)
    index+= 1
  end
  f_name.close
  return itemlist
end

# Monster-Liste laden für die Namen der Gegner
def read_monsters()
  f_name = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/MONNAMES.LTX", "rb")
  
  monsters = []
  index = 0
  until f_name.eof?
    name = ""
    while((c = f_name.read(1)) != "\0") do name+=c; end
    monsters << name_s(name)
    index+= 1
  end
  f_name.close
  return monsters
end

itemlist = read_items
monlist  = read_monsters

file = File.open("/home/hendrik/repos/BrightEyes/tools/nltpack/out-roa2/FIGHT.LST", "rb")
num_fights = file.read(2).unpack("S<")[0]
puts "Datei enthält #{num_fights} Kämpfe."
fightlist = Array.new()
for i in 0...num_fights
  fight = Fight.new

  fight.name = file.read(20).unpack("a*")[0].delete("\0")
  fight.id   = file.read(2).unpack("S")[0]
  for i in 0...20
    fighter = Fighter.new
    fighter.id     = file.read(1).unpack("C")[0]
    fighter.posx   = file.read(1).unpack("C")[0]
    fighter.posy   = file.read(1).unpack("C")[0]
    fighter.lookat = file.read(1).unpack("C")[0]
    fighter.when   = file.read(1).unpack("C")[0]
    fight.enemies << fighter unless fighter.id == 0
  end
  for i in 0...7
    fighter = Fighter.new
    fighter.posx   = file.read(1).unpack("C")[0]
    fighter.posy   = file.read(1).unpack("C")[0]
    fighter.lookat = file.read(1).unpack("C")[0]
    fighter.when   = file.read(1).unpack("C")[0]
    fight.players << fighter
  end
  # Group by fighters
  for e in fight.enemies do
    grp = fight.enemy_groups.find{|eg|
      eg.id == e.id  &&  eg.when == e.when
    }
    if grp == nil
      fighter = e.clone
      fighter.number = 1
      fight.enemy_groups << fighter
    else
      grp.number += 1
    end
  end
  for i in 0...30
    fight.loot << file.read(2).unpack("S")[0]
  end
  fight.loot.delete(0)
  mdata = file.read(6).unpack("SSS")
  fight.money = mdata[2] + 10*(mdata[1] + 10*mdata[0])
  fightlist << fight
end

for fight in fightlist
  puts "#{fight.name}: #{fight.enemies.size} fighters:"
  for eg in fight.enemy_groups
    puts "   - #{eg.number} x #{monlist[eg.id]}[#{eg.id}] in round #{eg.when}"
  end
#  for e in fight.enemies
#    puts "   - #{monlist[e.id]}[#{e.id}]"
#  end
  
#  puts " Loot: #{fight.money} Heller"
#  for l in fight.loot
#    puts "   - #{itemlist[l]}"
#  end
end

file.close
p monlist.size
