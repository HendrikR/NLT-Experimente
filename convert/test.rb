for req in [ "compression", "ace", "aif", "bob", "nvf", "tga", "uli" ] do
  filename = "./test_" + req + ".rb"
  require filename
end
