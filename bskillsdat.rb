# -*- coding: utf-8 -*-
# 1300 Bytes, in offensichtlichen 4er-Blöcken angeordnet.
# Macht 13*4*25 Bytes, also offenbar 25 Werte pro Heldentypus (den 0er-Dummy inbegriffen)
# Pro 4er-Block:
# 00: Skill-Index
# 01: 0x00
# 02: entweder 0x0B oder 0x63 (selten auch andere Werte, z.B. 0x05). Irgendwelche Flags?
# 03: 0x00
# Vermutung: Dürfte die Tabelle zum automatischen Talentsteigern sein.
# BSKILLS = Beginner-Skills?


names_skill = ["Waffenlos", "Hiebwaffen", "Stichwaffen", "Schwerter", "Äxte", "Speere", "Zweihänder", "Schusswaffen", "Wurfwaffen",
               "Akrobatik", "Klettern", "Körperbeh.", "Reiten", "Schleichen", "Schwimmen", "Selbstbeh.", "Tanzen", "Verstecken", "Zechen",
               "Bekehren", "Betören", "Feilschen", "Gassenwissen", "Lügen", "Menschenkenntnis", "Schätzen",
               "Fährtensuchen", "Fesseln", "Orientierung", "Pflanzenkunde", "Tierkunde", "Wildnisleben",
               "Alchimie", "Alte Sprachen", "Geographie", "Geschichte", "Götter/Kulte", "Kriegskunst", "Lesen", "Magiekunde", "Sprachen",
               "Abrichten", "Fahrzeuge", "Falschspiel", "Heilen Gift", "Heilen Krankheit", "Heilen Wunden", "Musizieren", "Schlösser", "Taschendieb",
               "Gefahrensinn", "Sinnenschärfe"]

f = File.new("BSKILLS.DAT", "rb")

heldentypen = ["DUMMY", "Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]


class BSkill
  # Entscheidend scheint die Reihenfolge zu sein, denn oben kommen immer besonders wichtige Skills.
  # Die Flags sind noch etwas rätselhaft, vermutlich geben sie an, wie oft gesteigert werden soll, was beim Misslingen passiert u.ä.
  # Wert 0x05 kommt in den Flags nur bei einem Talent vor, nämlich Lesen, und dort bei allen Typen außer Gaukler (kann nicht lesen) und Magier (99)
  
  attr_accessor :skill, :unk1, :flags, :unk3
  def initialize(u1,u2,u3,u4)
    @skill = u1
    @unk1  = u2
    @flags  = u3
    @unk3  = u4
  end
end

werte = {}

heldentypen.each do |typus|
  werte[typus] = []
  25.times{
    werte[typus] << BSkill.new(*(f.read(4).bytes))
  }
end

werte.each do |typus,skills|
  puts "==== #{typus} ===="
  skills.each_with_index do |s,i|
    idx = s.skill
    puts "#{names_skill[idx]}: #{s.flags}"
  end
end

f.close
