# coding: utf-8
# Konstanten
TYPUS = ["Gaukler", "Jäger", "Krieger", "Streuner", "Thorwaler", "Zwerg", "Hexe", "Druide", "Magier", "Auelf", "Firnelf", "Waldelf"]
SKILL = ["Waffenlos", "Hiebwaffen", "Stichwaffen", "Schwerter", "Äxte", "Speere", "Zweihänder", "Schusswaffen", "Wurfwaffen",
         "Akrobatik", "Klettern", "Körperbeh.", "Reiten", "Schleichen", "Schwimmen", "Selbstbeh.", "Tanzen", "Verstecken", "Zechen",
         "Bekehren", "Betören", "Feilschen", "Gassenwissen", "Lügen", "Menschenkenntnis", "Schätzen",
         "Fährtensuchen", "Fesseln", "Orientierung", "Pflanzenkunde", "Tierkunde", "Wildnisleben",
         "Alchimie", "Alte Sprachen", "Geographie", "Geschichte", "Götter/Kulte", "Kriegskunst", "Lesen", "Magiekunde", "Sprachen",
         "Abrichten", "Fahrzeuge", "Falschspiel", "Heilen Gift", "Heilen Krankheit", "Heilen Wunden", "Musizieren", "Schlösser", "Taschendieb",
         "Gefahrensinn", "Sinnenschärfe"]
SPELL = ["DUMMY",
         "Beherrschung brechen", "Destructibo", "Gardianum", "Illusionen zerstören", "Verwandlung beenden", # Antimagie
         "Band + Fessel", "Bannbaladin", "Böser Blick", "Große Gier", "Große Verwirrung", "Herr der Tiere", "Horriphobus", "Mag. Raub", "Respondami", "Sanftmut", "Somnigravis", "Zwingtanz", # Beherrschung
         "Furor Blut", "Geister bannen", "Geister rufen", "Heptagon", "Krähenruf", "Skelettarius", # Dämonologie
         "Elementar herbeirufen", "Nihilatio Gravitas", "Solidrid Farbenspiel", # Elementarmagie
         "Axxeleraus", "Foramen", "Motoricus", "Spurlos, Trittlos", "Transversalis", "Über Eis", # Bewegung
         "Balsam", "Hexenspeichel", "Klarum Purum", "Ruhe Körper", "Tiere heilen", # Heilung
         "Adleraug", "Analüs", "Eigenschaften", "Exposami", "Odem Arcanum", "Penetrizzel", "Sensibar", # Hellsicht
         "Chamaelioni", "Duplicatus", "Harmlos", "Hexenknoten", # Illusion
         "Blitz", "Ecliptifactus", "Eisenrost", "Fulminictus", "Ignifaxius", "Plumbumbarum", "Radau", "Saft, Kraft, Monstermacht", "Scharfes Auge", # Kampf
         "Hexenblick", "Nekropathia", # Verständigung
         "Adler, Wolf", "Arcano Psychostabilis", "Armatrutz", "CH steigern", "Feuerbann", "FF steigern", "GE steigern", "IN steigern", "KK steigern", "KL steigern", "MU steigern", "Mutabili", "Paralü", "Salander", "See + Fluss", "Visibili", # Verwandlung
         "Abvenenum", "Aeolitus", "Brenne", "Claudibus", "Dunkelheit", "Erstarre", "Flim Flam", "Schmelze", "Silentium", "Sturmgebrüll"] # Veränderung

ITEMNAMES = ["Bloße Hand", "Schwert", "Knüppel", "Säbel", "Messer", "Speer", "Kurzschwert", "Schild", "Kriegsbeil", "Kurzbogen", "Pfeil", "Streitaxt", "Armbrust", "Bolzen", "Dolch", "Eisenschild", "Wurfbeil", "Wurfstern", "Zweihänder", "Langbogen", "Morgenstern", "Vulkanglasdolch", "Fackel", "Bier", "Wurfhaken", "Laterne", "Brecheisen", "Hammer", "Angelhaken", "Buch", "Wasserschlauch", "Glasflasche", "Strickleiter", "Wurfaxt", "Messingspiegel", "Dietriche", "Schreibzeug", "Harfe", "Trinkhorn", "Silberschmuck", "Kletterhaken", "Öl", "Bronzeflasche", "Eisenhelm", "Pike", "Proviantpaket", "Flöte", "Alchimieset", "Hemd", "Hose", "Schuhe", "Stiefel", "Schneeschuhe", "Lederharnisch", "Schuppenpanzer", "Shurinknollengift", "Araxgift", "Angstgift", "Schlafgift", "Goldleim", "Vierblättrige Einbeere", "Wirselkraut", "Eitriger Krötenschemel", "Gulmond Blatt", "Tarnele", "Fackel", "Streitkolben", "Degen", "Florett", "Kampfstab", "Kristallkugel", "Peitsche", "Decke", "Schaufel", "Goldschmuck", "Robe", "Robe", "Topfhelm", "Lederhelm", "Waffenrock", "Kettenhemd", "Krötenhaut", "Plattenzeug", "Kettenzeug", "Lederzeug", "Zunderkästchen", "Schleifstein", "Essbesteck", "Essgeschirr", "Lakritze", "Bonbons", "Weinflasche", "Schnapsflasche", "Hacke", "Praios Amulett", "Laute", "Wintermantel", "Netz", "Wurfmesser", "Sichel", "Sense", "Kriegshammer", "Dreizack", "Hellebarde", "Dreschflegel", "Zweililien", "Ochsenherde", "Basiliskenzunge", "Ogerfänger", "Mengbilar", "Dolch (schwer)", "Rondrakamm", "Entermesser", "Bastardschwert", "Tuzakmesser", "Rabenschnabel", "Brabakbengel", "Rapier", "Khunchomer", "Doppelkhunchomer", "Kupferscheibe", "Seil", "Shurinknolle", "Belmart Blatt", "Donfstengel", "Menchalkaktus", "Alraune", "Atmonblüte", "Ilmenblatt", "Finagebäumchen", "Jorugawurzel", "Thonnysblüte", "Lotosblüte", "Zauberstab", "Skraja", "Kriegsbeil", "Orknase", "Schneidzahn", "Robbentöter", "Wolfmesser", "Hexenbesen", "Lotosgift", "Kukris", "Bannstaub", "Krötenschemelgift", "Heiltrank", "Starker Heiltrank", "MU Elixier", "KL Elixier", "CH Elixier", "FF Elixier", "GE Elixier", "IN Elixier", "KK Elixier", "Zaubertrank", "Starker Zaubertrank", "Olginwurzel", "Kairanhalm", "Bastardschwert", "Orknase", "Kurzschwert", "Sichel", "Feueramulett", "Amulett (blau)", "Depotschein", "Ring (rot)", "Expurgicum", "Rezept für Expurgicum", "Vomicum", "Rezept für Vomicum", "Depotschein", "Stirnreif (silber)", "Säbel", "Amulett (rot)", "Amulett (grün)", "Travia Amulett", "Depotschein", "Mondscheibe (rot)", "Zweihänder", "Asthenilmesser", "Gegengift", "Erzklumpen", "Totenkopfgürtel", "Kraftgürtel", "Brotbeutel (magisch)", "Wasserschlauch (magisch)", "Rezept für Heiltrank", "Schlüssel (grob)", "Amulett", "Lobpreisungen", "Mitgliederliste", "Rezeptbuch", "Münzen (rot)", "Kukrisdolch", "Bronzeschlüssel", "Goldschlüssel (reich verziert)", "Helm", "Kettenhemd", "Kettenhemd", "Schwert", "Kukrismengbilar", "Silberschlüssel (reich verziert)", "Rezept für Gegengift", "Rezept für Hylailer Feuer", "Rezept für Kraftelixier", "Rezept für Mutelixier", "Rezept für Zaubertrank", "Ring (blau)", "Doppelbartschlüssel", "Kupferschlüssel (groß)", "Silberschlüssel", "Goldschlüssel", "Pfeilschlüssel (rot)", "Silberhelm", "Silberstreitkolben", "Silberschmuck", "Speer", "Stirnreif (blau)", "Wurfdolch", "Bogenschlüssel (rot)", "Ring (grün)", "Schmuck (rot)", "Brillenschlüssel (golden)", "Anti-Krankheitselixier", "Asthenil Dolch", "Holzkohle", "MU Elixier", "KL Elixier", "CH Elixier", "FF Elixier", "GE Elixier", "IN Elixier", "KK Elixier", "Robe", "Schild (gold)", "Asthenilschwert", "Wunderkur", "Schlaftrunk", "Miasthmaticum", "Hylailer Feuer", "Rezept für Starken Heiltrank", "Rezept für Wunderkur", "Rezept für Schlaftrunk", "Rezept für Starken Zaubertrank", "Rezept für Miasthmaticum", "Stirnreif (grün)", "Buch", "Schmuck (grün)", "Schwarze Statuette", "Laterne", "Edelsteine", "Ring (silber)", "Salamanderstein", "Brosche", "Herzschlüssel", "Schwert des Artherion", "Bogen des Artherion", "Schwere Armbrust", "Wurfaxt (golden)", "Schädelschlüssel", "Kristall", "Stab", "Leuchtstab (grün)", "Leuchtstab (orange)", "Kristallkugel", "Stirnband", "Knochenschlüssel", "Trockenwirselkraut", "Klare Flüssigkeit", "Amuletteil", "Amuletteil", "Amuletteil", "Amuletteil", "Gußeisenschlüssel", "Orksäbel", "Orkschmuck", "Orkbeil", "Gruufhai", "Ringelpanzer", "Salamanderstein", "Zwergengoldschlüssel", "Kupferschlüssel", "Mondsichelamulett", "Ork-Tuchrüstung", "Borndorn", "Ork-Lederrüstung", "Asthenilring", "Edelsteine (grün)", "Münzen (grün)", "Fisch", "Fisch", "Otterfell", "Ring (schwarz)", "Luchsohr", "Schlafsack", "Kupferkessel", "Superheiltrank", "Dokument des Bannstrahlordens", "Streitkolben", "Runendokument", "Luchsschlüssel", "Bogenschlüssel (silbern)", "Zangenschlüssel", "Zinnschlüssel", "Goldschlüssel (klein)", "Silberschlüssel (klein)", "Eisenschlüssel", "Lowangen-Schlüssel", "Schlüssel (blau)", "Vierblättrige Einbeere (trocken)", "Vierblättrige Einbeere (trocken)", "Lederhose", "Lederstiefel", "Lederwams", "Pergamente", "Feuerpulver", "Steinmedaillon", "Orkbogen", "Dämonenbuch", "Magistratsdokument", "Edelstein", "Spiegelamulett", "Wein", "Armreif (rot)", "Armreif (grün)", "Schlüsselbund", "Sumpfrantze", "Helm", "Drachenklaue", "Kult-Dokument", "Päckchen", "Dokument", "Dokument", "Sumpfrantzendokument", "Heidekraut", "Heidekraut", "Noctrux-Dokument", "Kristallkugel", "Rezept für Geldscheißer", "Geldscheißer", "Schwert", "Phiole", "Wagenschmiere", "Kurbel", "Kette", "Drachenkopfring", "Dokument", "Flammenschlüssel", "Drachentöter", "Zweihänder", "Phexenhelm", "Phexenschild", "Dukaten", "200 Pfeile", "50 Bolzen", "20 Kletterhaken"]

MONTH_NAME = ["NL", "PRA", "RON", "EFF", "TRA", "BOR", "HES", "FIR", "TSA", "PHE", "PER", "ING", "RAH"]

def read_item_names(file)
  # Hilfsfunktionen
  def name_s(name)
    arr = name.split('.')
    if arr.size == 1 then arr[0]
    else arr[0]+arr[1]; end
  end

  # Namen der Items einlesen
  f_name = File.open("/home/hendrik/code/cpp/freenlt/dsa2/out/ITEMS.LTX", "rb:CP850:utf-8")
  #f_name = File.open(file, "rb:CP850:utf-8")
  
  items = f_name.read.split("\0")
  items = items.inject([]) {|arr,i| arr << name_s(i)}
  f_name.close
  return items
end
