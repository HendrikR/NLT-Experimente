# -*- coding: utf-8 -*-

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

f = File.new("SPBVALS.DAT", "rb")

heldentypen = ["Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]

werte = {}

heldentypen.each do |typus|
  werte[typus] =  f.read(86).unpack("c*")
end

werte.each do |typus,skills|
  puts "==== #{typus} ===="
  for i in 1...86 do
    print " #{names_spell[i]}: #{skills[i]}"
    if i==5 or i==17 or i==23 or i==26 or i==32 or i==37 or
      i==44 or i==48 or i==57 or i==59 or i==75
      print "\n"
    else
      print ", "
    end
  end
  puts
end
f.close
