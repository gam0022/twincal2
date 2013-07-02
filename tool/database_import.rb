# coding: utf-8

require 'sqlite3'
require 'csv'

database_filename = "kamoku.db"
csv_filename = "kdb_20130703013255_2.csv"
tabale_name = "kamoku2013"

db = SQLite3::Database.new(database_filename)
db.busy_timeout(100000)

# kcode	科目名	単位数	標準履修年次	実施学期	曜時限	教室	担当教員	授業概要	備考	科目等履修生履修可否	理由
db.execute("create table #{tabale_name} (kcode text, 科目名 text, 単位数 text, 標準履修年次 text, 実施学期 text, 曜時限 text, 教室 text, 担当教員 text, 授業概要 text, 備考 text, 科目等履修生履修可否 text, 理由 text)")

db.execute("create index kcode on #{tabale_name}(kcode)")

table = CSV.parse(File.open(csv_filename).read.encode("UTF-8", "CP932"))

table.each do |row|
  str = "insert into #{tabale_name} values(#{row.take(12).map{|s| 
    s ? "'#{s.gsub("'", "''")}'" : "''"
  }.join(",")})"
  #p str
  db.execute(str)
end

db.close
