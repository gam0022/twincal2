#! /usr/bin/ruby
# coding: utf-8

require_relative 'functions.rb'

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

  database_filename = "kamoku.db"
  table_name = "kamoku"

  db = SQLite3::Database.new(database_filename)
  db.busy_timeout(100000)

  table = CSV.parse(cgi.params['file'][0].read)
  subjects = []

  table.each do |csv_row|
    kcode = csv_row[0].delete("\n\r").gsub("'", "''")
    sql = "select * from #{table_name} where kcode = '#{kcode}'"
    db.execute(sql) do |row|
    #sql = "select * from #{table_name} where kcode = ?"
    #db.execute(sql, kcode) do |row|

      s = {
        :code => row[0],
        :name => row[1],
        :tani => row[2],
        :location => row[6],
        :teacher => row[7]
      }

      term_s = row[4]
      parse_term(term_s).each do |term|

        jigen_ss = row[5] # ex: 木5,6 / 集中 / 応談 / 随時 / 火・金5
        parse_jigen(jigen_ss).each do |jigen|

          date = get_term_start_each_wday(Date.parse(term[:begin]))[jigen[:wday]]
          s[:start] = Time.parse(date + " " + P_START[jigen[:start] - 1]).to_icsf
          s[:end]   = Time.parse(date + " " + P_END[jigen[:end] - 1]).to_icsf

          s[:wday]  = jigen[:wday]
          # 繰り返しの終了日
          s[:until] = Time.parse(term[:end]).to_icsf

          subjects << deep_copy(s)
        end
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
  db.close

  # ログ
  log(table.join(','), "./success.log")

rescue => e
  # エラー処理
  exception_handling(e, cgi) 
  db.close
end
