#!/usr/bin/env ruby
# -*- encoding: UTF-8 -*-

#
#メモツール
#ruby 1.9のみ対応
#

require 'pp'
require 'csv'
require 'cgi'
require "tempfile"
require 'fileutils'
require 'optparse'
require './lib/memo'

#------- global variable
Version = "0.0.5"
MemoDir = File.expand_path('~/.rmemo')
Editor = 'vim'
#------- global variable


#------- option
option = {}

parser = OptionParser.new
parser.banner = "rmemo.rb is CLI based memo tool by ruby.\n"
parser.banner += "Memo's directory is \"#{MemoDir}\".\n"
parser.banner += "Usage: #{File.basename($0)} {option}"
parser.on("-a", "--add", "add memo."){
  option[:add] = true
}
parser.on("-d", "--date Date", String, "search range by date. Date is 20090131, 0131, 31,..."){|get_arg|
  option[:date] = get_arg
}
parser.on("-g", "--git OPTION", String, "git command to #{MemoDir}."){|get_arg|
  option[:git] = get_arg
}
parser.on("-i", "--ignore-case", "Ignore case distinctions. use with -s option"){
  option[:reg_opt] = 'i'
}
parser.on("-f", "--fullpath", "put full path format."){
  option[:fullpath] = true
}
parser.on("-n", "--num [NUMBER]", String, "puts number memo. NUMBER is 0,1,2,..., 0..9"){|get_arg|
  option[:number] = 0..9
  option[:number] = eval(get_arg) if get_arg
}
parser.on("-p", "--put", "puts all memo."){
  option[:put] = true
}
parser.on("-r", "--reverse", "reverse out puts."){
  option[:reverse] = true
}
parser.on("-s", "--search PATTERN", String, "puts search result."){|get_arg|
  option[:search] = get_arg
}
parser.on("-t", "--title", "puts title of memo."){
  option[:title] = true
}
parser.on("-v", "--version", "print rmemo.rb version and quit."){
  option[:version] = true
}
parser.on("-C", "--count", "memo count."){
  option[:count] = true
}
parser.on("-D", "--dir DIR", String, "set memo dir."){|get_arg|
  option[:dir] = get_arg
}
parser.on("-R", "--random", "random puts memo."){
  option[:random] = true
}

begin
  parser.parse!
rescue OptionParser::ParseError => err
  $stderr.puts err.message
  $stderr.puts parser.help
  exit 1
end

if option.empty?
  puts parser.help
  exit 1
end
#------- option

class String
  #String convert to array of date
  def to_date
    case self.length
    when 8 #year + mon + day
      [self[0..3], self[4..5], self[6..7]]
    when 6 #year + mon
      [self[0..3], self[4..5]]
    when 4 #year
      [self[0..3]]
    else
      nil
    end
  end
end

#add new memo
def add(memo)
  tmp = Tempfile.open('memo', MemoDir)
  tmp.close

  system("#{Editor} #{tmp.path}")
  str = File.open(tmp.path, 'r').read
  memo.add(str) unless str.empty?
end

dir = 'memo'
dir = option[:dir] if option.include?(:dir)
dir = File.join(MemoDir, dir)
FileUtils.mkdir_p(dir) unless Dir.exist?(dir)
memo = Memo.new(dir)

format = []
ary = []
year = nil
mon = nil
day = nil
option.each do |key, val|
  case key
  when :git
    unless Dir.exist?(File.join(MemoDir, ".git"))
      STDERR.puts "Error'Not found git directory."
      exit(1)
    end
    Dir.chdir(MemoDir)
    system("git #{option[:git]}")
    exit(0)
  when :add
    add(memo)
    exit
  when :date
    date = option[:date].to_date
    if date
      year = date[0]
      mon  = date[1]
      day  = date[2]
    end
  when :count,:fullpath,:random,:put,:title
    format << key
    ary = memo.list(year, mon, day) if ary.empty?
  when :search
    ary = memo.list(year, mon, day).search(val, option[:reg_opt])
  when :version
    puts Version
    exit
  end
end

ary = ary.reverse if option.include?(:reverse)
ary = ary[option[:number]] if option.include?(:number)
if ary.class == Memo::MemoFile
  ary = [ary].to_memo
end

case format[-1]
when :count
  puts ary.size
when :fullpath
  puts ary.map{|v|v.to_p}
when :put
  puts ary.map{|v|v.read}
when :random
  srand(Time.now.to_i)
  puts ary[rand(ary.size)].read
when :title
  puts ary.map{|v|v.to_s}
else
  puts ary.map{|v|v.read}
end
