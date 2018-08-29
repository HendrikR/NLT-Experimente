require './ace.rb'
require './aif.rb'
require './bob_new.rb'
require './bob_old.rb'
require './nvf.rb'
require './raw.rb'
require './tga.rb'
require './uli.rb'

$EXTENSION_HANDLERS = {
#  "ACE" => ACE.new,
#  "AIF" => AIF.new,
#  "BOB" => BOB.new,
#  "NVF" => NVF.new,
#  "RAW" => RAW.new,
  "TGA" => TGA.new,
  "ULI" => ULI.new
}

