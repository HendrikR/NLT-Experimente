# -*- coding: utf-8 -*-
zuordnung = {
0x00=>:MU,
0x01=>:KL,
0x02=>:CH,
0x03=>:FF,
0x04=>:GE,
0x05=>:IN,
0x06=>:KK,
0x07=>:AG,
0x08=>:HA,
0x09=>:RA,
0x0A=>:GG,
0x0B=>:TA,
0x0C=>:NG,
0x0D=>:JZ
}

f = File.new("NEEDS.DAT", "rb")
#types = []
#ctype = {}
while (data = f.read(2)) != nil
  data = data.bytes
  if data[0] == 0 and data[1] == 0
    puts # nächster Heldentyp
  else
    if data[1] < 0x80 then val = data[1]; else val = -(data[1]-0x80); end
    printf("%s: %d ", zuordnung[data[0]].to_s, val)
    #ctype[data[0]] = data[1]
  end
end
=begin
Reihenfolge in der Datei:
dazwischen sind ständig 0en, warum auch immer.
Gaukler
Jäger
Krieger
Streuner
Thorwaler
Zwerg
Hexe
Druide
Magier
Auelf
Firnelf
Waldelf
=end
