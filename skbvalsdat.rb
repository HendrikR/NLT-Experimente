# -*- coding: utf-8 -*-
names_skill = ["Waffenlos", "Hiebwaffen", "Stichwaffen", "Schwerter", "Äxte", "Speere", "Zweihänder", "Schusswaffen", "Wurfwaffen",
               "Akrobatik", "Klettern", "Körperbeh.", "Reiten", "Schleichen", "Schwimmen", "Selbstbeh.", "Tanzen", "Verstecken", "Zechen",
               "Bekehren", "Betören", "Feilschen", "Gassenwissen", "Lügen", "Menschenkenntnis", "Schätzen",
               "Fährtensuchen", "Fesseln", "Orientierung", "Pflanzenkunde", "Tierkunde", "Wildnisleben",
               "Alchimie", "Alte Sprachen", "Geographie", "Geschichte", "Götter/Kulte", "Kriegskunst", "Lesen", "Magiekunde", "Sprachen",
               "Abrichten", "Fahrzeuge", "Falschspiel", "Heilen Gift", "Heilen Krankheit", "Heilen Wunden", "Musizieren", "Schlösser", "Taschendieb",
               "Gefahrensinn", "Sinnenschärfe"]

f = File.new("SKBVALS.DAT", "rb")

heldentypen = ["DUMMY", "Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]

werte = {}

heldentypen.each do |typus|
  werte[typus] =  f.read(52).unpack("c*")
end

werte.each do |typus,skills|
  puts "==== #{typus} ===="
  for i in 0...52 do
    print " #{names_skill[i]}: #{skills[i]}"
    if i==8 or i==18 or i==25 or i==31 or i==49 or i==51
      print "\n"
    else
      print ","
    end
  end
  puts
end
f.close
