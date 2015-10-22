# -*- coding: utf-8 -*-
# Es gibt 85 (mit "DUMMY" 86) Zauber und 9 Magierschulen.

names_spell = ["DUMMY",
               "Beherrschung brechen", "Destructibo", "Gardianum", "Illusionen zerstören", "Verwandlung beenden", # Antimagie
               "Band & Fessel", "Bannbaladin", "Böser Blick", "Große Gier", "Große Verwirrung", "Herr der Tiere", "Horriphobus", "Mag. Raub", "Respondami", "Sanftmut", "Somnigravis", "Zwingtanz", # Beherrschung
               "Furor Blut", "Geister bannen", "Geister rufen", "Heptagon", "Krähenruf", "Skelettarius", # Dämonologie
               "Elementar herbeirufen", "Nihilatio Gravitas", "Solidrid Farbenspiel", # Elementarmagie
               "Axxeleraus", "Foramen", "Motoricus", "Spurlos, Trittlos", "Transversalis", "Über Eis", # Bewegung
               "Balsam", "Hexenspeichel", "Klarum Purum", "Ruhe Körper", "Tiere heilen", # Heilung
               "Adleraug", "Analüs", "Eigenschaften", "Exposami", "Odem Arcanum", "Penetrizzel", "Sensibar", # Hellsicht
               "Chamaelioni", "Duplicatus", "Harmlos", "Hexenknoten", # Illusion
               "Blitz", "Ecliptifactus", "Eisenrost", "Fulminictus", "Ignifaxius", "Plumbumbarum", "Radau", "Saft, Kraft, Monstermacht", "Scharfes Auge", # Kampf
               "Hexenblick", "Nekropathia", # Verständigung
               "Adler, Wolf", "Arcano Psychostabilis", "Armatrutz", "CH steigern", "Feuerbann", "FF steigern", "GE steigern", "IN steigern", "KK steigern", "KL steigern", "MU steigern", "Mutabili", "Paralü", "Salander", "See & Fluss", "Visibili", # Verwandlung
               "Abvenenum", "Aeolitus", "Brenne", "Claudibus", "Dunkelheit", "Erstarre", "Flim Flam", "Schmelze", "Silentium", "Sturmgebrüll"] # Veränderung



f = File.new("SCHOOL.DAT", "rb")
schools = ["Antimagie", "Beherrschung", "Beschwörung", "Bewegung", "Heilung", "Hellsicht", "Kampf", "Verwandlung", "Veränderung"]
boni = Array.new(9)
for school in 0...9 do
  #printf "%x\n" % f.tell
  keys = []; vals = []
  anz_boni = f.read(1).bytes[0]
  #puts "Schule #{school} hat #{anz_boni} boni."
  for i in 0...anz_boni
    data = f.read(2).bytes
    keys << data[0] + (data[1] << 8)
  end
  check = [0,0]
  while check != [0xFF, 0xFF] do check = f.read(2).bytes; end
  
  for i in 0...anz_boni
    data = f.read(2).bytes
    vals << data[0] + (data[1] << 8)
  end
  boni[school] = keys.zip(vals)

  check = [0,0]
  while check == [0,0] and not f.eof? do
    check = f.read(2).bytes
  end
  f.seek(-2, IO::SEEK_CUR)
end


for school in 0...9 do
  printf("%s:\n", schools[school])
  boni[school].each {|bonus|
    printf("%s: +%d, ", names_spell[bonus[0]], bonus[1])
  }
  puts
end
f.close
