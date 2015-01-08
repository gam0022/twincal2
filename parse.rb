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

  DATABASE_FILENAME = CONFIG["database"]["filename"]
  COLUMN_NAMES = CONFIG["database"]["column_names"]
  TABLE_NAME = CONFIG["database"]["table_name"]

  db = SQLite3::Database.new(DATABASE_FILENAME)
  db.busy_timeout(100000)
  db.results_as_hash = true

  table = CSV.parse(cgi.params['file'][0].read)
  subjects = []

  table.each do |csv_row|
    code = csv_row[0].delete("\n\r").gsub("'", "''")
    sql = "select * from #{TABLE_NAME} where code = '#{code}'"
    db.execute(sql) do |row|
    #sql = "select * from #{TABLE_NAME} where code = ?"
    #db.execute(sql, code) do |row|

      s = {
        :code => row["code"],
        :name => row["name"],
        :tani => row["unit"],
        :location => row["location"],
        :teacher => row["teacher"]
      }

      term_s = row["term"]
      parse_term(term_s).each do |term|

        jigen_ss = row["period"] # ex: 木5,6 / 集中 / 応談 / 随時 / 火・金5
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
