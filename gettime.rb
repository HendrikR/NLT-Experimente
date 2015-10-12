# coding: utf-8
# Sucht in Schicksalsklinge-Spielständen nach dem Spieldatum und zeigt es an.
f = File.open(ARGV[0])
f.seek(0x0088+0x13)
timedata = f.read(8).unpack("SCCCcCc")
f.close
ticksprosekunde = 0x10000 / (12*3600.0)
ticksseit0uhr = timedata[0] + 0xFFFF*timedata[1]
sekundenseit0uhr = ticksseit0uhr / ticksprosekunde
stunde = sekundenseit0uhr / 3600
minute = (sekundenseit0uhr - (3600*stunde)) / 60
wochentag = 
  case(timedata[3])
  when 0; "Rohalstag"
  when 1; "Feuertag"
  when 2; "Wassertag"
  when 3; "Windstag"
  when 4; "Erdstag"
  when 5; "Markttag"
  when 6; "Praiostag"
  else    "KAPUTT"
  end
tagimmonat = timedata[4]
monatsname = 
  case(timedata[5])
  when 0; "NL"
  when 1; "PRA"
  when 2; "RON"
  when 3; "EFF"
  when 4; "TRA"
  when 5; "BOR"
  when 6; "HES"
  when 7; "FIR"
  when 8; "TSA"
  when 9; "PHE"
  when 10; "PER"
  when 11; "ING"
  when 12; "RAH"
  else "KAPUTT"
  end
jahr = timedata[6]
printf("Es ist %s, der %d. %s %d nach Hal, %02d:%02d\n", wochentag, tagimmonat, monatsname, jahr, stunde, minute)
