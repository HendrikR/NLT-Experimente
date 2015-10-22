f_xdialog = File.open(ARGV[0]+"/XDIALOG.DAT", "rb")
f_stdtalks= File.open(ARGV[0]+"/STDTALKS.LTX", "rb:CP850:utf-8")
f_topics  = File.open(ARGV[0]+"/TOPICS.TOP", "rb:CP850:utf-8")

class Dialog
  attr_accessor :question, :goodanswer, :badanswer, :num_questions, :num_goodanswers, :num_badanswers
  def initialize(data)
    data = data.unpack("S<S<S<CCC")
    @question        = data[0]
    @goodanswer      = data[1]
    @badanswer       = data[2]
    @num_questions   = data[3]
    @num_goodanswers = data[4]
    @num_badanswers  = data[5]
  end
end

dialogs = []
while not f_xdialog.eof?
  dialogs << Dialog.new(f_xdialog.read(9))
end

texts = []
f_stdtalks.each("\0") {|str|
  texts << str.chop.gsub("\u000d", "\\n").gsub(/^<|>$/, "")
}

topics = []
f_topics.each {|str|
  str = str.match("([A-Z0-9]*)[[:space:]]*\"(.*)\"\r\n")
  topics << [str[1], str[2]]
}


for i in 0...topics.size
  topic = topics[i]
  dialog = dialogs[i]
  puts "* Thema: #{topic[1]} (#{topic[0]})"
  puts "** Fragen (#{dialog.num_questions}):"
  for i in 0...dialog.num_questions do
    puts "- " + texts[dialog.question+i]
  end
  puts "** gute Antworten (#{dialog.num_goodanswers}):"
  for i in 0...dialog.num_goodanswers do
    puts "- " + texts[dialog.goodanswer+i]
  end
  puts "** schlechte Antworten (#{dialog.num_badanswers}):"
  for i in 0...dialog.num_badanswers do
    puts "- " + texts[dialog.badanswer+i]
  end
end
