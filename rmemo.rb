#!/usr/bin/env ruby

Signal.trap("INT") {exit}

if RUBY_VERSION.split('.')[0].to_i < 2
  puts 'ruby version is low!'
  puts 'ruby update >=2.0.0, please!'
  exit(1)
end

require 'optparse'
require 'fileutils'
require 'tempfile'

VERSION = "0.0.9.16"
MEMODIR = File.expand_path('~/.rmemo')
EDITOR = 'vim'

class String
  def to_regxp(option=nil)
    #return @reg if @reg

    begin
      raise unless self =~ /\/.*\/[[:alpha:]]/o
      obj = eval(self)
      reg = obj if obj.class == Regexp
    rescue => e
      reg = Regexp.new(self, option=option)
    end
    #@reg = reg
    reg
  end

  def with_color(options=nil)
    return self unless options

    nums = []
    escape = "\e[%sm"

    colors = {black:'0', red:'1', green:'2', yellow:'3', blue:'4', magenta:'5', cyan:'6', white:'7'}
    nums << '3'+colors[options[:color].to_sym] if options[:color]
    nums << '4'+colors[options[:backgrand].to_sym] if options[:backgrand]

    attrs = {bold:'1', low:'2', underline:'4', blink:'5', reverse:'7', invisible:'8'}
    nums << attrs[options[:attr].to_sym] if options[:attr]

    head = escape % nums.join(':')
    tail = escape % ""
    return head + self + tail
  end
end

class Memo
  include Enumerable
  def initialize(path, reverse)
    @top_path = File.expand_path(path)
    @reverse = reverse
  end

  def Memo.add(path, str)
    path = "#{path}/#{Time.now.strftime("%Y/%m/%d")}"
    @top_path = File.expand_path(path)

    file_no = Dir.glob("#{@top_path}#{'/*'}").length
    if file_no == 0
      FileUtils.mkdir_p(@top_path)
    end
    memo_file = MemoFile.new("#{@top_path}/#{file_no}")
    memo_file.contents = str
  end

  def path_depth
    path = @top_path.split(/\//)[-3..-1]
    if /[0-9]/ =~ path[2] and /[0-9]/ =~ path[1] and /[0-9]/ =~ path[0]
      return 3
    elsif /[0-9]/ =~ path[2] and /[0-9]/ =~ path[1]
      return 2
    elsif /[0-9]/ =~ path[2]
      return 1
    else
      return 0
    end
  end

  def each
    count = 3 - path_depth
    if @reverse
      Dir.glob("#{@top_path}#{'/*'*count}").each do |path|
        Dir.glob("#{path}/*").each.sort_by{|v|v.split('/')[-1].to_i}.each do |file|
          yield MemoFile.new(file)
        end
      end
    else
      #最新の情報がでるように、デフォルトはreverse_eachを使う
      Dir.glob("#{@top_path}#{'/*'*count}").reverse_each do |path|
        Dir.glob("#{path}/*").each.sort_by{|v|v.split('/')[-1].to_i}.reverse_each do |file|
          yield MemoFile.new(file)
        end
      end
    end
  end

  class MemoFile
    def initialize(path)
      @path = path
    end
    attr_reader :path

    def date
      @path.split('/')[-4..-1].join('/')
    end

    def title
      File.open(@path) do |f|
        f.readline.chomp
      end
    end

    def contents
      File.read(@path)
    end

    def contents=(str)
      File.open(@path, 'w') do |f|
        f << str
      end
    end

    def search(str, option=nil)
      reg = str.to_regxp(option)
      reg =~ self.contents
    end
  end
end

#------- option
option = {}

parser = OptionParser.new
parser.banner = "rmemo.rb is CLI based memo tool by ruby.\n"
parser.banner += "Memo's directory is \"#{MEMODIR}\".\n"
parser.banner += "Usage: #{File.basename($0)} {option}"
parser.on("-a", "--add", "add memo."){
  option[:add] = true
}
parser.on("-d", "--date Date", String, "search range by date. Date is 2013,2013-01,2013-01-31,..."){|get_arg|
  option[:date] = get_arg
}
parser.on("-e", "--edit", String, "edit file, but condision is desided one file."){|get_arg|
  option[:edit] = true
}

parser.on("-E", "--disable-escape", String, "disable output escape."){|get_arg|
  option[:disable_escape] = true
}

parser.on("-g", "--git OPTION", String, "git root path:#{MEMODIR}"){|get_arg|
  option[:git] = get_arg
}
parser.on("-i", "--ignore-case", "Ignore case distinctions. use with -s option"){
  option[:reg_opt] = [] if not option[:reg_opt]
  option[:reg_opt] << 'i'
}
parser.on("-f", "--fullpath", "put full path format."){
  option.delete(:title)
  option[:fullpath] = true
}
parser.on("-n", "--num [NUMBER]", String, "puts number memo. NUMBER is 0,1,2,..., 0..9"){|get_arg|
  option[:number] = 0..9
  option[:number] = eval(get_arg) rescue nil if get_arg
  unless option[:number]
    STDERR.puts "Argument Error"
    exit 1
  end
}
parser.on("-p", "--put", "puts all memo."){
  option[:put] = true
}
parser.on("-r", "--reverse", "reverse out puts."){
  option[:reverse] = true
}
parser.on("-s", "--search PATTERN", String, "puts search result."){|get_arg|
  option[:search] = [] if not option[:search]
  option[:search] << get_arg
}
parser.on("-t", "--title", "puts title of memo."){
  option.delete(:fullpath)
  option[:title] = true
}
parser.on("-v", "--version", "print rmemo.rb version and quit."){
  option[:version] = true
}
parser.on("-C", "--count", "memo count."){
  option[:count] = true
}
parser.on("-D", "--dir [DIR]", String, "set memo dir."){|get_arg|
  unless get_arg
    top_path = File.expand_path('~/.rmemo')
    Dir.glob("#{top_path}/*").each do |path|
      puts path.split('/')[-1]
    end
    exit
  end
  option[:dir] = get_arg
}
parser.on("-R", "--random", "random puts memo."){
  option[:random] = true
}

begin
  parser.parse!
  raise OptionParser::ParseError if option.empty?
rescue OptionParser::ParseError => err
  $stderr.puts err.message
  $stderr.puts parser.help
  exit 1
end
#------- option

dir = 'memo'
dir = option[:dir] if option[:dir]
if option.key?(:date)
  sub_dir = option[:date].split('-')
  dir = [dir] + sub_dir
  dir = dir.join('/')
end

reverse = false
reverse = true if option.key?(:reverse)
rmemo = Memo.new("~/.rmemo/#{dir}", reverse)
rmemo_enum = rmemo.lazy.each

option.each do |key, val|
  case key
  when :add
    tmp = Tempfile.open('memo', MEMODIR)

    system("#{EDITOR} #{tmp.path}")
    str = File.open(tmp.path, 'r').read
    Memo.add("~/.rmemo/#{dir}", str) unless str.empty?

    tmp.close(true)
    exit
  when :git
    unless Dir.exist?(File.join(MEMODIR, ".git"))
      $stderr.puts "Error'Not found git directory."
      exit(1)
    end
    Dir.chdir(MEMODIR)
    system("git #{option[:git]}")
    exit
  when :version
    puts VERSION
    exit
  end
end

option.each do |key, val|
  case key
  when :search
    val.each do |v|
      rmemo_enum = rmemo_enum.lazy.select{|memo|memo if memo.search(v, option[:reg_opt])}
    end
  end
end

option.each do |key, val|
  case key
  when :count
    puts rmemo_enum.to_a.count
    exit
  when :number
    val = val...val+1 if val.kind_of?(Integer)
    rmemo_enum = rmemo_enum.to_a[val]
  end
end

option.each do |key, val|
  rmemo_enum = rmemo_enum.to_a
  if rmemo_enum.count.zero?
    STDERR.puts "Error: memo not found"
    exit 1
  end

  case key
  when :edit
    system("#{EDITOR} #{rmemo_enum[0].path}")
    exit
  when :fullpath,:title
    memos_carry_size = rmemo_enum.count.to_s.size
    rmemo_enum.each_with_index do |memo,i|
      options = nil
      options = (i%2).zero? ? {attr:'bold'} : nil unless option.has_key?(:disable_escape)

      if key == :fullpath
        info = memo.path
      elsif key == :title
        info = memo.date
      end
      is = sprintf("%#{memos_carry_size}d", i)
      puts "#{is}:[#{info}]@ #{memo.title}".with_color(options)
    end
  when :put
    rmemo_enum.each_with_index do |memo,i|
      contents = memo.contents
      option[:search].each do |key|
        key2 = key.with_color({color:'red'})
        contents = contents.gsub(/#{key}/, key2)
      end if option.include?(:search)
      puts contents
      puts ""
    end
  end
end
