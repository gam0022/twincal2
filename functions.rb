#! /usr/bin/ruby
# coding: utf-8

require 'time'
require 'date'
require 'erb'
require 'cgi'
require 'yaml'

class Time

  # http://www.asahi-net.or.jp/~CI5M-NMR/iCal/ref.html
  # 日付と時刻を一緒に記述する時は、間を T で区切る。例： 19980119T230000
  def to_icsf
    self.strftime("%Y%m%dT%H%M00")
  end

end

class Hash
  # http://d.hatena.ne.jp/hamajyotan/20110226/1298739617
  def map_to_hash &block
    ret = {}
    each { |k,v| ret[k] = block.call(v) }
    ret
  end
end

#
# 各曜日の授業開始日を求める
#
def get_term_start_each_wday(term_start)

  term_start_each_wday = Array.new

  current = term_start
  i = (yday = term_start.yday)
  j = (wday = term_start.wday)

  while i < (yday + 7) do
    term_start_each_wday[j] = current.to_s
    i += 1
    j = (j+1)%7
    current = current.next
  end

  term_start_each_wday
end

#
# オブジェクトを深いコピーする
#
def deep_copy(obj)
  Marshal.load(Marshal.dump(obj))
end

#
# ログ
#
def log(str, file)
  open(file, "a") do |f|
    f.write("[#{Time.now.to_s}] #{str}\n")
  end
end

#
# エラー処理は全部これ
#
def exception_handling(e, cgi)
  log(e.to_s + "\n" + e.backtrace.join("\n"), "./error.log")

  print cgi.header( {
    "status"     => "REDIRECT",
    "Location"   => "./?has_error=true"
  })
end
