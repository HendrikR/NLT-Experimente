#!/usr/bin/ruby
# Waffenoptimierung für die Nordlandtrilogie.
# (C) 2009 by Hendrik Radke.
class Waffe
  attr_accessor(:name, :art, :tp, :at_bonus, :pa_bonus, :tp, :kk_zuschlag, :bf)
  attr_accessor(:gewicht, :helden_dsa1, :helden_dsa2, :comment)
  def tp_num;  @tp[0..0].to_i;  end
  def tp_add;  @tp[3...@tp.size].to_i;  end
  def initialize(name, art)
    @name = name
    @art  = art
  end
end

class Held
  class ATPA
    attr_accessor(:at, :pa)
    def initialize(at,pa); @at=at; @pa=pa; end
  end
  attr_accessor(:name, :atpa, :kk)
  def initialize(name)
    @name = name
    @kk   = 10
    @atpa = Hash.new
  end
end

weapons = Hash.new

# Waffentabelle, neu. Erzeugt aus den Original-Tabellen mit folgendem Skript.
# Original-Tabellen können direkt von http://nlt-hilfe.crystals-dsa-foren.de/page.php?20 bezogen werden.
=begin
waffentabelle.split("\n").each { | line |
  cells = line.split("\t")
  weapon = Waffe.new(cells[0], cells[1])
  weapon.tp          = cells[2]
  weapon.at_bonus    = cells[3].split("/")[0].to_i
  weapon.pa_bonus    = cells[3].split("/")[1].to_i
  weapon.gewicht     = cells[4].to_i
  weapon.helden_dsa1 = cells[5]
  weapon.helden_dsa2 = cells[6]
  weapon.comment     = cells[7]
  weapons[weapon.name] = weapon
}

bruchfaktortabelle.split("\n").each { | line |
  cells = line.split("\t")
  weapons[cells[0]].kk_zuschlag = cells[1].to_i
  weapons[cells[0]].bf          = cells[2].to_i
  if (cells[3] != nil)
    weapons[cells[3]].kk_zuschlag = cells[4].to_i
    weapons[cells[3]].bf          = cells[5].to_i
  end
}

printf("Name\tWaffengattung\tTP\tAT-/PA-Bonus\tKK-Zuschlag\tBF\tGewicht\tMaske 1\tMaske 2\tKommentar\n")
weapons.each {|(name,w)| 
  printf("%s", "#{w.name}\t#{w.art}\t#{w.tp}\t#{w.at_bonus}/#{w.pa_bonus}\t")
  printf("%s", "#{w.kk_zuschlag}\t#{w.bf}\t#{w.gewicht}\t")
  printf("%s", "#{w.helden_dsa1}\t#{w.helden_dsa2}\t#{w.comment}\n")
}
=end
# Ende des Tabellen-Erzeugungs-Scriptes. Beginn der Waffentabelle.
# Name	Waffengattung	TP	AT-/PA-Bonus	KK-Zuschlag	BF	Gewicht	Maske 1	Maske 2	Kommentar
waffentabelle = <<EOF
Kukrisdolch	Stichwaffen	1W+1	-2/-3	15	3	20	GJ STZHMDAFW	GJ STZHM AFW	! DSA2: 30 U. [2]
Pike	Stichwaffen	1W+3	-1/-4	19	7	150	GJKST AFW	* 	
Basiliskenzunge	Stichwaffen	1W+1	-2/-3	16	4	25	GJKSTZHMDAFW	GJKSTZHM AFW	
Doppelkhunchomer	Hiebwaffen	1W+6	-1/-3	15	3	150	K	nT/Ov/L/O	
Kurzschwert (2)	Schwerter	1W+2	2/-1	15	9	40	GJKSTZ AFW	! magisch 	
Florett	Stichwaffen	1W+3	0/-1	16	3	30	GJKSTZ AFW		
Orknase	Aexte	1W+5	-1/-3	14	2	120	GJKSTZ AFW		
Rapier	Stichwaffen	1W+3	0/-1	16	4	35	GJKSTZ AFW		
Peitsche	Hiebwaffen	1W+0	0/-6	19	2	60	GJKSTZHMDAFW	GJKSTZH DAFW	
Wolfmesser	Stichwaffen	1W+3	0/-1	15	2	50	GJKSTZ AFW	O * 	
Morgenstern	Hiebwaffen	1W+5	-1/-3	15	5	120	K Z		
Messer	Stichwaffen	1W	-3/-4	16	4	10	GJKSTZHMDAFW		
Rabenschnabel	Hiebwaffen	1W+4	-1/-3	16	3	90	GJKSTZ AFW	* 	
Zweihaender	Zweihaender	2W+4	-2/-3	14	3	160	K		
Tuzakmesser	Zweihaender	1W+6	-2/-2	15	1	135	K	nT/Ov/L/O 	
Schwert	Schwerter	1W+4	0/0	14	2	80	GJKSTZ AFW		
Kriegshammer	Hiebwaffen	2W+3	-2/-4	15	2	150	K Z	* 	
Knueppel	Hiebwaffen	1W+1	-1/-3	14	6	60	GJKSTZ DAFW		
Kampfstab	Speere	1W+1	0/-1	15	5	70	GJKSTZHMDAFW	GJKSTZ DAFW	
Saebel (2)	Hiebwaffen	?	0/0	15	0	0	?	! magisch 	
Streitkolben	Hiebwaffen	1W+4	0/-2	13	1	110	GJKSTZ AFW	K Z	
Sichel	Hiebwaffen	1W+2	-3/-4	17	5	30	GJKSTZ AFW		
Zweihaender (2)	Zweihaender	2W+4	-3/-4	14	9	160	K Z	K ! magisch	
Schneidzahn	Wurfwaffen	1W+4	0/0	0	0	50	GJKSTZ AFW		
Entermesser	Hiebwaffen	1W+3	0/-1	15	2	70	GJKSTZ AFW	*	
Kriegsbeil (2)	Aexte	1W+4	-2/-4	13	2	120	GJKSTZ AFW	* 	
Mengbilar	Stichwaffen	1W+1	-3/-4	16	7	20	GJKSTZHMDAFW	GJKSTZH AFW	nT/Ov/L/O
Schwert Grimring	Schwerter	1W+4	2/2	14	9	80	GJKSTZ AFW	! magisch; DSA2: -	
Dreizack	Stichwaffen	1W+3	0/-3	15	3	90	GJKSTZ AFW	* 	
Robbentoeter	Hiebwaffen	1W+3	0/0	15	2	70	GJKSTZ AFW	O	
Saebel	Hiebwaffen	1W+3	0/0	15	2	60	GJKSTZ AFW		
Blosse Hand	Waffenlos	1W	0/0	0	0	0	GJKSTZHMDAFW		
Bastardschwert	Zweihaender	1W+5	-1/-2	14	2	140	K Z	K 	
Wurfstern	Wurfwaffen	1W+1	0/0	0	0	15	GJKSTZHMDAFW	GJKSTZHM AFW	DSA2: stapeln
Rondrakamm	Zweihaender	2W+2	-2/-2	15	3	150	K 		
Kurzschwert	Schwerter	1W+2	0/-1	15	1	40	GJKSTZ AFW 		
Sense	Hiebwaffen	1W+3	-3/-4	17	6	100	GJKSTZ AFW		
Hellebarde	Aexte	1W+4	-1/-3	15	5	150	K		
Wurfbeil	Wurfwaffen	1W+3	-1/0	0	4	120	GJKSTZ AFW	DSA2: 60 U.	
Schleuder	Schusswaffen	1W+2	-1/0	0	0	10	GJKSTZHMDAFW	DSA2: -	
Hexenbesen	Hiebwaffen	1W+1	0/0	15	9	60	H	Hexen 	
Ochsenherde	Hiebwaffen	3W+3	-3/-4	17	4	240	K		
Wurfmesser	Wurfwaffen	1W	-3/0	0	4	10	GJKSTZHMDAFW		
Khunchomer	Hiebwaffen	1W+4	0/-1	14	2	70	GJKSTZ AFW 		
Zweililien	Hiebwaffen	1W+3	-1/-1	18	4	80	GJKSTZ AFW	K O *	
Wurfaxt	Wurfwaffen	1W+3	-1/0	0	4	120	GJKSTZHMDAFW	GJKSTZ AFW	
Armbrust	Schusswaffen	1W+6	-1/0	0	0	200	KSTZ AFW 		
Skraja	Hiebwaffen	1W+3	0/-2	13	4	90	GJKSTZ AFW	DSA2: Axt *	
Kriegsbeil	Aexte	1W+4	0/-3	14	5	120	GJKSTZHMDAFW	GJKSTZ AFW	
Bastardschwert (2)	Zweihaender	1W+5	-2/-3	14	0	50	K Z	K ! magisch	
Streitaxt	Zweihaender	2W+4	-1/-4	14	3	150	K TZ	K * 	
Kurzbogen	Schusswaffen	1W+3	-1/0	0	0	20	GJKSTZ DAFW	GJKSTZ AFW	
Dolch	Stichwaffen	1W+1	-2/-3	15	3	20	GJKSTZHMDAFW	GJKSTZHM AFW	
Speer (2)	Speere	1W+3	1/1	0	5	80	GJKSTZ AFW	! magisch 	
Kukrismengbilar	Stichwaffen	1W+1	-3/-4	16	7	20	GJ STZHMDAFW	GJ STZHAFW	! [3]
Langbogen	Schusswaffen	1W+4	-1/0	0	0	30	GJKSTZ DAFW	GJKSTZ AFW	
Orknase (2)	Aexte	1W+10	-2/-8	14	9	120	GJKSTZ AFW	! magisch 	
Bolzen (50)	Waffenlos	0W+0	0/0	0	0	5	GJKSTZHMDAFW		
Brabakbengel	Hiebwaffen	1W+5	-1/-2	14	1	120	GJKSTZ AFW 		
Degen	Stichwaffen	1W+3	0/-1	16	3	35	GJKSTZ AFW		
Dreschflegel	Hiebwaffen	1W+2	-2/-3	13	6	100	GJKST DAFW		
Silberstreitkolben	Hiebwaffen	1W+4	0/-2	13	1	110	GJKSTZ AFW	K Z 	! 
Pfeile (200)	Waffenlos	0W+0	0/0	0	0	4	GJKSTZHMDAFW		
Vulkanglasdolch	Stichwaffen	1W+0	-2/-3	16	6	30	GJKSTZHMDAFW	magisch/O	
Sichel (2)	Hiebwaffen	1W+2	-3/-4	17	5	30	GJKSTZ AFW	! magisch 	
Schwert (2)	Schwerter	1W+4	2/0	14	0	80	GJKSTZ AFW	! magisch 	
Ogerfaenger	Stichwaffen	1W+2	-2/-3	15	4	30	GJKSTZHMDAFW	GJKSTZH AFW 	
Wurfdolch	Wurfwaffen	1W	-3/0	0	4	10	GJKSTZHMDAFW	GJKSTZHM AFW	! magisch
Schwerer Dolch	Stichwaffen	1W+2	-1/-2	15	2	30	GJKSTZHMDAFW	GJKSTZH AFW 	
Zauberstab	Speere	1W+1	0/0	15	9	70	M	Magier 	
Speer	Speere	1W+3	0/-3	0	5	80	GJKSTZ AFW		
EOF

waffentabelle.split("\n").each { | line |
  cells = line.split("\t")
  weapon = Waffe.new(cells[0], cells[1])
  weapon.tp          = cells[2]
  weapon.at_bonus    = cells[3].split("/")[0].to_i
  weapon.pa_bonus    = cells[3].split("/")[1].to_i
  weapon.kk_zuschlag = cells[4].to_i
  weapon.bf          = cells[5].to_i
  weapon.gewicht     = cells[6].to_i
  weapon.helden_dsa1 = cells[7]
  weapon.helden_dsa2 = cells[8]
  weapon.comment     = cells[9]
  weapons[weapon.name] = weapon
}

#printf("Name\tWaffengattung\tTP\tAT-/PA-Bonus\tKK-Zuschlag\tBF\tGewicht\tMaske 1\tMaske 2\tKommentar\n")
#weapons.each {|(name,w)| 
#  printf("%s", "#{w.name}\t#{w.art}\t#{w.tp}\t#{w.at_bonus}/#{w.pa_bonus}\t")
#  printf("%s", "#{w.kk_zuschlag}\t#{w.bf}\t#{w.gewicht}\t")
#  printf("%s", "#{w.helden_dsa1}\t#{w.helden_dsa2}\t#{w.comment}\n")
#}

print "Name des Helden: "
name = gets.chomp
if name == "" then name = "Held"; end
held_kk = 0
until held_kk != 0
  print "KK:"
  held_kk = gets.chomp.to_i
end
held = Held.new(name)
held.kk = held_kk

art = ""
print "Waffengattungen hinzufuegen({Waffenlos, Aexte, Hiebwaffen, Schwerter, Speere, Stichwaffen, Zweihaender, Wurfwaffen, Schusswaffen}).
Bitte auf exakte Schreibung der Gattungen achten.
Eingabe von 'ende' als Gattung beendet die Eingabe.\n"
while true
  print "Waffengattung: "; art = gets.chomp
  if art == "ende" then break; end
  print "AT-Wert: "; at = gets.chomp.to_i
#  print "PA-Wert: "; pa = gets.chomp.to_i
  pa = 10
  held.atpa[art] = Held::ATPA.new(at, pa)
end

# Patzer/gute Attacken werden nicht beruecksichtigt.
puts "TP-Angabe: <Trefferwahrscheinl.>*<Wuerfel>+<Grundschaden>+<Zusatz-TP durch KK>"
puts "Patzer/gute Attacken werden nicht beruecksichtigt."
bestewaffe = Waffe.new("Dummy", "Dummy")
bestewaffe.tp = "0W+0"
beste_tp      = 0
beste_kkz     = 0
beste_at_prob = 0
weapons.each_value { | waffe |
  if held.atpa[waffe.art] == nil then next; end
  if held.kk > waffe.kk_zuschlag && waffe.kk_zuschlag > 0
    kk_add = held.kk - waffe.kk_zuschlag
  else
    kk_add = 0
  end
  at_prob = (held.atpa[waffe.art].at + waffe.at_bonus)/20.0
  #pa_prob = (held.atpa[waffe.art].pa + waffe.pa_bonus)/20.0
  tp_durchschnitt = (waffe.tp_num*3.5 + waffe.tp_add + kk_add) * at_prob
  if tp_durchschnitt > beste_tp
    print "#{waffe.name} schlaegt #{bestewaffe.name} "
    print "mit #{at_prob}*#{waffe.tp_num}W+#{waffe.tp_add}+#{kk_add} "
    print "vs. #{beste_at_prob}*#{bestewaffe.tp_num}W+#{bestewaffe.tp_add}+#{beste_kkz}\n"
    beste_tp      = tp_durchschnitt
    bestewaffe    = waffe
    beste_kkz     = kk_add
    beste_at_prob = at_prob
  end
}
print "Beste Waffe fuer #{held.name}: #{bestewaffe.name} mit durchschnittlich #{beste_tp} TP\n"
print "<ENTER> zum Beenden"
gets
