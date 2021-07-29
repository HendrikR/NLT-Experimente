for req in [ "compression", "ace", "aif", "bob", "nvf", "tga", "uli" ] do
  fork {
    filename = "./test_" + req + ".rb"
    require filename
  }
end
