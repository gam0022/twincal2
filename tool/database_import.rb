# coding: utf-8

require 'sqlite3'
require 'csv'
require 'yaml'

def escape_sql(str)
  str ? "'#{str.gsub("'", "''")}'" : "''"
end

# usage: 
# $ rm kamoku.db
# $ ruby database_import.rb kdb_20140402080858_2.csv

csv_filename = ARGV[0]

CONFIG = YAML.load_file("../config.yml")
DATABASE_FILENAME = CONFIG["database"]["filename"]
COLUMN_NAMES = CONFIG["database"]["column_names"]
TABLE_NAME = CONFIG["database"]["table_name"]

db = SQLite3::Database.new(DATABASE_FILENAME)
db.busy_timeout(100000)

db.execute("create table #{TABLE_NAME} (id integer primary key, #{COLUMN_NAMES.map{|c| "#{c} text"}.join(',')})")
db.execute("create index code_index on #{TABLE_NAME}(code)")

table = CSV.parse(File.open(csv_filename).read.encode("UTF-8", "CP932"))

row_count = 0

table.each do |row|
  str = "insert into #{TABLE_NAME}(#{COLUMN_NAMES.join(',')}) values(#{row.take(15).map{|s| escape_sql(s)}.join(",")})"
  #p str
  db.execute(str)

  row_count += 1
end

db.close

puts "正常に処理が終了しました。(#{row_count}件)"
