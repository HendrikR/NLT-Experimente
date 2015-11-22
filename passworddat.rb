class Password
  attr_accessor :bPage, :bLine, :bWord
  attr_accessor :seedA, :seedB
  attr_accessor :pwCode, :pwClear

  def initialize(data)
    @bWord, @bLine, @bPage, @seedA, @seedB, @pwCode = data.unpack("CCC CC a*")
    decode
  end

  def decode
    @pwClear = ""
    seedA = @seedA
    seedB = @seedB
    for i in 0...20 do
      c = @pwCode[i].ord
      d = seedA ^ (c - seedB)
      @pwClear += (d & 0xFF).chr
      #printf("code %02x  decode %02x/%c  seedA %02x  seedB %02x\n", c, d, (d&0xFF), seedA, seedB)
      seedB += seedA ^ d
      seedA ^= d
    end
  end
  def encode(str)
    pass = ""
    seedA = @seedA
    seedB = @seedB
    for i in 0...str.size do
      c = str[i].ord
      #printf("seedA %02x  seedB %02x  char %02x\n", seedA, seedB, c)
      pass+= (((seedA ^ c) + seedB) & 0xFF).chr
      seedB += seedA ^ c
      seedA ^= c
    end
    return pass
  end
  def to_s
    sprintf("Seite %3d, Zeile %2d, Wort %d:\t%s",
            @bPage, @bLine, @bWord, @pwClear)
  end
end

file = File.open(ARGV[0], "r")
count = file.read(2).unpack("S<")[0]

pass = []
count.times {|pw|
  data = file.read(25)
  pass << Password.new(data)
  puts pass.last
}

#pass.first.encode("KVIRASIM").each_byte{|x|printf("%02x ", x)}; puts
pass.first.decode
