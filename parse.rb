#! /usr/bin/ruby
# coding: utf-8

require_relative 'functions.rb'
require_relative './lib/kdb.rb'

class View

  def initialize(subjects)
    @subjects = subjects
    @DTSTAMP = @CREATED = @LAST_MODIFIED = Time.now.to_icsf
  end

  extend ERB::DefMethod
  def_erb_method('to_ics', 'views/ics_format.erb')

end

begin

  cgi = CGI.new

  kdb = KDB::KDB.new(cgi.params['file'][0].read)
  subjects = []
  kdb.subjects.each do |i|
    s = {
      code: i.kcode,
      name: i.科目名,
      tani: i.単位数,
      location: i.教室,
      teacher: i.担当教員
    }

    i.term.each do |term|
      i.period.each do |period|
        date = get_term_start_each_wday(Date.parse(term[:begin]))[period[:wday]]
        s[:start] = Time.parse(date + " " + KDB::P_START[period[:start] - 1]).to_icsf
        s[:end]   = Time.parse(date + " " + KDB::P_END[period[:end] - 1]).to_icsf

        s[:wday]  = period[:wday]
        # 繰り返しの終了日
        s[:until] = Time.parse(term[:end]).to_icsf

        subjects << deep_copy(s)
      end
    end
  end

  # ICS ファイル出力
  print "Content-Disposition: attachment; filename=\"twincal.ics\"\r\n"
  print cgi.header(
    "charset"=>"UTF-8",
    "type"=>'application/octet-stream; name="twincal.ics"'
  )
  print View.new(subjects).to_ics
  ActiveRecord::Base.connection.close

  # ログ
  log(kdb.subjects.map{|i| i.kcode }.join(','), "./success.log")

rescue => e
  # エラー処理
  exception_handling(e, cgi) 
  ActiveRecord::Base.connection.close
end
