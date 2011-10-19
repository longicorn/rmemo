class File
  #File.split("a/b/c/") =>["a/b", "c"]
  #File.splitall("a/b/c/") =>["a", "b", "c"]
  def File.splitall(str)
    str.split(File::SEPARATOR)
  end
end
