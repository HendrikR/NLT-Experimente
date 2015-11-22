# coding: utf-8
require_relative("_common.rb")

class Chest
  def initialize(data)
    data = data.unpack("C2 S2 C6 S*")
    @unk1     = data[0] # immer 0
    @unk2     = data[1] # immer 0
    @money    = data[2] # In Silberstücken
    @key_item = data[3] # meist 0, ansonsten ein öffnendes Item
    @unk3     = data[4] # meist 255
    @unk4     = data[5] # meist 255
    @unk5     = data[6] # immer 0
    @unk6     = data[7] # meist 1
    @unk7     = data[9] # meist 0
    @items    = Hash[*(data[10..-1])]
    @items.delete(0xFFFF)
    #p @items
  end
  def item_str
    arr = []
    @items.each_pair{|item,count|
      arr << count.to_s + " " + ITEMNAMES[item]
    }
    if arr.empty? then return "<leer>"
    else return arr.join(", "); end
  end
  def to_s
    item_str
  end
end

file = File.open(ARGV[0])
49.times{
  c = Chest.new(file.read(52))
  puts c
}
