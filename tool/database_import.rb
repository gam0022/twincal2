# coding: utf-8

require 'sqlite3'
require 'csv'

# usage: 
# $ rm kamoku.db
# $ ruby database_import.rb kdb_20140402080858_2.csv

database_filename = "kamoku.db"
csv_filename = ARGV[0]
table_name = "kamoku"

db = SQLite3::Database.new(database_filename)
db.busy_timeout(100000)

# kcode	科目名	単位数	標準履修年次	実施学期	曜時限	教室	担当教員	授業概要	備考	科目等履修生履修可否	理由
db.execute("create table #{table_name} (kcode text, 科目名 text, 単位数 text, 標準履修年次 text, 実施学期 text, 曜時限 text, 教室 text, 担当教員 text, 授業概要 text, 備考 text, 科目等履修生履修可否 text, 理由 text)")

db.execute("create index kcode_index on #{table_name}(kcode)")

table = CSV.parse(File.open(csv_filename).read.encode("UTF-8", "CP932"))

row_count = 0

table.each do |row|
  str = "insert into #{table_name} values(#{row.take(12).map{|s| 
    s ? "'#{s.gsub("'", "''")}'" : "''"
  }.join(",")})"
  #p str
  db.execute(str)

  row_count += 1
end

db.close

puts "正常に処理が終了しました。(#{row_count}件)"
