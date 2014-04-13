#! /usr/bin/ruby
# coding: utf-8

require 'csv'
require 'time'
require 'date'
require 'sqlite3'
require 'cgi'
require 'erb'

P_START   = ["8:40", "10:10", "12:15", "13:45", "15:15", "16:45"]
P_END     = ["9:55", "11:25", "13:30", "15:00", "16:30", "18:00"]

WEEK      = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
WEEK_JP   = ["日", "月", "火", "水", "木", "金", "土"]

WDAY_MAP = {
  "日" => 0,
  "月" => 1,
  "火" => 2,
  "水" => 3,
  "木" => 4,
  "金" => 5,
  "土" => 6
}

# 学年暦 refs
# http://www.tsukunavi.com/life/shinseikatsu2014/daigaku/schedule.html

TERM_BEGIN = {
  "春" => {
    "A" => "2014/04/11",
    "B" => "2014/05/23",
    "C" => "2014/07/04"
  },
  "夏" => "2014/08/09",
  "秋" => {
    "A" => "2014/10/01",
    "B" => "2014/11/08",
    "C" => "2014/12/24"
  }
}

# 13:00 となっているのは、GMTで指定するため (JSTなら、22:00)
TERM_END = {
  "春" => {
    "A" => "2014/05/22 13:00",
    "B" => "2014/07/01 13:00",
    "C" => "2014/08/06 13:00"
  },
  "夏" => "2014/09/30 13:00",
  "秋" => {
    "A" => "2014/11/07 13:00",
    "B" => "2014/12/26 13:00",
    "C" => "2015/02/12 13:00"
  }
}

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
# 曜時限をパースする
# input:  月・木4,5
# retrun: [[wday, start, end], [wday, start, end], ...]
#
def parse_jigen(str)
  ret = []
  str.lines do |line|
    rscan = line.scan(/^(\D+)([\d\-,]+)$/)
    if rscan.size == 1
      wday_ss = rscan[0][0]
      koma_ss = rscan[0][1]

      wday_ss.split("・").each do |wday_s|
        wday = WDAY_MAP[wday_s]

        if koma_ss =~ /^[\d,s]+$/
          kstart = kend = nil
          pre_k = 0

          koma_ss.split(",").each do |k_s|
            k = k_s.to_i
            if pre_k == 0 || k == pre_k + 1
              kend = k
            else
              ret << {:wday => wday, :start => kstart, :end => kend}
              kstart = kend = nil
            end
            kstart = k unless kstart
            kend = k unless kend
            pre_k = k
          end

          ret << {:wday => wday, :start => kstart, :end => kend}

        elsif koma_ss =~ /^[\d\-]+$/
          kstart = koma_ss[0].to_i
          kend   = koma_ss[2].to_i
          ret << {:wday => wday, :start => kstart, :end => kend}
        end
      end
    end
  end
  ret
end

#
# 実施学期をパースする
# input:
#   - 春C秋ABC
#   - 集中
#   - 通年
#   - 春AB秋AB
#   - 夏季休業中
# retrun: [[date_begin, date_end], [date_bigin, date_end], ...]
#
def parse_term(str)
  ret = []
  str.lines do |line|

    line = "春ABC秋ABC" if line == "通年"

    if line.gsub!("夏季休業中", '')
      ret << {:begin => TERM_BEGIN["夏"], :end => TERM_END["夏"]}
    end

    rscan = line.strip.scan(/[春秋][ABC]+/)
    rscan.each do |item|
      term = item[0]
      mod = item[1..10]

      begin_ = end_ = nil
      case mod.size
      when 1
        begin_ = end_ = mod 
      when 2
        begin_ = mod[0]
        end_   = mod[1]
      when 3
        begin_ = mod[0]
        end_   = mod[2]
      end
      ret << {:begin => TERM_BEGIN[term][begin_], :end => TERM_END[term][end_]}
    end

  end
  ret
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

#TERM_MAP = {
#  "春AB"  => :S_AB, 
#  "春ABC" => :S_ABC, 
#  "春C"   => :S_C,
#  "秋AB"  => :A_AB, 
#  "秋ABC" => :A_ABC, 
#  "秋C"   => :A_C
#}
#
#TERM_START = {
#  :S_AB  => "2013/04/12",
#  :S_ABC => "2013/04/12",
#  :S_C   => "2013/07/03",
#  :A_AB  => "2013/10/01",
#  :A_ABC => "2013/10/01",
#  :A_C   => "2013/12/23"
#}
#TERM_END   = {
#  :S_AB  => "2013/07/02 22:00",
#  :S_ABC => "2013/08/07 22:00",
#  :S_C   => "2013/08/07 22:00",
#  :A_AB  => "2013/12/20 22:00",
#  :A_ABC => "2014/02/07 22:00",
#  :A_C   => "2014/02/07 22:00"
#}
