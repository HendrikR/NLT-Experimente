class Bob < Format
  def initialize()
    @@formats[:bob] = 0 unless @@formats.has_key?(:bob)
  end

  def Read(filename)
  end

  def Write(filename)
  end
end
