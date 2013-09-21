# -*- coding: utf-8 -*-

# Tabelle zum automatischen Zaubersteigern.
# Pro 2er-Block:
# 00: Skill-Index
# 01: 0x00
# GBSPELLS = General Beginner Spells?
# Zwischen den einzelnen Magier-Typen scheint kein Unterschied gemacht zu werden.

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

f = File.new("GBSPELL.DAT", "rb")


heldentypen = ["Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]


class BSkill
  attr_accessor :skill, :unk1
  def initialize(u1,u2)
    @skill = u1
    @unk1  = u2
  end
end

werte = {}

heldentypen.each do |typus|
  werte[typus] = []
  45.times{
    werte[typus] << BSkill.new(*(f.read(2).bytes))
  }
end

werte.each do |typus,skills|
  puts "==== #{typus} ===="
  skills.each_with_index do |s,i|
    idx = s.skill
    puts "#{names_spell[idx]}: #{s.unk1}"
  end
end

f.close
