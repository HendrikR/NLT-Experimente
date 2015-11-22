# coding: utf-8
# Binge6.dbg
# Interessante Punkte in Level 6 der Binge:
# (4,2): Ausgang Lvl7; (0,0x13): Ausgang Lvl5
# Binge7.dbg
# Interessante Punkte in Level 6 der Binge:
# (1,1): Ausgang Lvl5 (Schacht)
# (5,1): Zugemauerter Durchgang (Text 0x0F aus binge7.ltx)
# (9,2): Tür
# (D,2): Spezialtür
# (F,2): Ausgang Lvl6
# (0,3): Ausgang Gebirge
# (11,3):Truhe
# (6,7): Wasser (bzw. (7,7)?)
# (C,C) bis (C,E): heiße Platten
# Format sind offensichtlich 256 Werte à 3 Bytes.

require_relative("_common.rb")

file = File.new(ARGV[0])
=begin
16.times{|y|
  16.times{|x|
    a,b,c = file.read(3).unpack("CCC")
    #printf("%02x ", a, b)
    if a != 0
      if b != 0 or c!= 0
        printf("#")
      else
        printf("a")
      end
    else
      if b != 0 or c!=0
        printf("b")
      else
        printf(" ")
      end
    end
  }
  printf("\n")
}
=end
256.times{|i|
  a,b,c = file.read(3).unpack("CCC")
  printf("%02x: %x, %x, %x\n", i, a,b,c) unless a==0
}
