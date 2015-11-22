# Konvertiert einen DSA2-Spielstand der englischen Version (Star Trail)
# in einen Spielstand der deutschen Version (Sternenschweif)

$file = File.new(ARGV[0], "r+")

def getap(idx)
  ofs = 0x0120 + idx * 0x5F5
  $file.seek(ofs + 0x10)
  name = $file.read(0x10).unpack("Z*")[0]
  $file.seek(ofs + 0x28)
  ap   = $file.read(0x04).unpack("L<")[0]
  return [name,ap]
end

def setap(idx, val)
  ofs = 0x0120 + idx * 0x5F5
  $file.seek(ofs+0x28)
  $file.write([val].pack("L<"))
end

for i in 0..6 do
  name,ap = getap(i)
  newap = (ap / 50).round
  puts "#{name}: #{ap} --> #{newap}"
  #setap(i, newap)
end

