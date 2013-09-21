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
  for i in 0...86 do
    puts "#{names_spell[i]}: #{skills[i]}"
  end
end
f.close
