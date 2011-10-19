#!/usr/bin/env ruby
# encoding: UTF-8

#
# = memo.rb
#   memo tool liblaly
#   ruby 1.9 only
#
# == Format
#
# === Directory Format
#     path/year/month/day/n
#     pathはnewに渡すトップディレクトリ
#     year,month,dayは年月日
#     nは0からの連番
#
# === File Format
#     基本的にはフリーフォーマットとする。
#     制限はMemo::MemoFile#to_sで表示するときは1行目を使用する。
#     これは1行目をタイトルと想定している
#     それ以外はクラスを使用する側で決めれば良い
#

require 'fileutils'
require './lib/dir'
require './lib/file'

class Memo
  def initialize(path)
    @top_path = File.expand_path(path)
    @num = nil #検索数 nilは全数
  end
  attr_reader :top_path

  #@top_pathから年月日を元にしたディレクトリ名を生成する
  def path(year=nil, mon=nil, day=nil)
    y = year.to_s
    m = mon.to_s
    m = ('0' + m)[-2..-1] if mon
    d = day.to_s
    d = ('0' + d)[-2..-1] if day

    File.join(@top_path, y, m, d)
  end
  private :path

  #メモファイル名リスト(配列)を取得する
  def list(year=nil, mon=nil, day=nil)
    dir = path(year, mon, day)
    return [].to_memo unless File.exist?(dir)
    Dir.glob2(dir).map{|v|v.to_memo}.to_memo.compact
  end

  #年月日のディレクトリにあるファイルの数(正確には最後のファイル名+1)
  #ファイルは0オリジンなのでこの数が次のファイル番号
  def file_num(year, mon, day)
    lis = list(year, mon, day)
    return 0 if lis.empty?

    File.basename(lis.sort[-1]).to_i+1
  end
  private :file_num

  def add(str)
    time = Time.now
    n = file_num(time.year, time.month, time.day)

    dir = path(time.year, time.mon, time.day)
    FileUtils.mkdir_p(dir) if n == 0
    file = File.join(dir, n.to_s)

    File.open(file, "w").write(str)
  end

  #メモファイル名配列
  class MemoArray < Array
    #検索
    #syste(grep)でもいいけどせっかくなのでRubyの正規表現が使えるように自前でgrep
    def search(str, option=nil)
      reg = Regexp.new(str, option)
      self.map do |file|
        if reg =~ file.read
          file
        end
      end.compact
    end
  end

  #class of memo file name
  #メモファイル名クラス
  class MemoFile < String
    def to_date
      File.join(File.splitall(self)[-4..-2])
    end
    private :to_date

    def read
      File.open(self, 'r').read
    end

    def readlines
      read.lines.to_a
    end

    #puts fullpath and first line
    def to_pathline
      "[#{self}]@ #{readlines[0]}"
    end
    alias :to_p :to_pathline

    #puts date and first line
    def to_string
      "[#{to_date}]@ #{readlines[0]}"
    end
    alias :to_s :to_string
  end
end

class String
  def to_memo
    Memo::MemoFile.new(self)
  end
end

class Array
  def to_memo
    Memo::MemoArray.new(self)
  end

  alias :compact_org :compact
  def compact
    self.compact_org.map{|v|v unless File.basename(v)[0] == '.'}.compact_org.to_memo
  end
end
