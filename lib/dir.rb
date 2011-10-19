require 'pp'

class Dir
  #再帰的にglobを行う
  def Dir.glob2(path)
    ary = []

    Dir.foreach(path) do |v|
      next if v == '.' || v == '..'

      v = File.join(path, v)

      if File.directory?(v)
        ary << glob2(v)
      else
        ary << v
      end
    end

    ary.flatten.sort.reverse
  end
end
