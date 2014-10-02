#! /usr/bin/ruby
# coding: utf-8

require 'csv'
require 'time'
require 'date'
require 'sqlite3'
require 'cgi'
require 'erb'
require 'yaml'
require 'active_record'
require_relative './model/kamoku.rb'

module KDB
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

  CONFIG = YAML.load_file(File.expand_path("../../config.yml", __FILE__))

  P_START   = CONFIG["P"]["START"]
  P_END     = CONFIG["P"]["END"]

  TERM_BEGIN = CONFIG["TERM"]["BEGIN"]
  TERM_END = CONFIG["TERM"]["END"]

  class KDB
    class Subject
      attr_reader :period, :term
      def initialize(obj, period, term)
        @obj = obj
        @period = period
        @term = term
      end
      
      def method_missing(action, *args)
        if args == []
          @obj.send(action)
        else
          @obj.send(action, args)
        end 
      end
    end

    attr_reader :subjects

    def initialize(str)
      @subject_code = CSV.parse(str).flatten.map{|i| i.delete("\n\r").gsub("'", "''") }
      ActiveRecord::Base.establish_connection(
        adapter: "sqlite3",
        database: "./kamoku.db"
      )

      kcode = Kamoku.arel_table[:kcode]
      s = nil
      @subject_code.each.with_index do |code, i|
        @db = if i == 0
          s = kcode.eq(code)
        else 
          s = s.or(kcode.eq(code))
        end
      end

      if s.nil?
        
      else
        subjects = Kamoku.where(s) 
        @subjects = []
        subjects.each do |i|
          period = parse_period(i.曜時限)
          term = parse_term(i.実施学期)
          @subjects << Subject.new(i, period, term)
        end
      end
    end

    #
    # 曜時限をパースする
    # input:  月・木4,5
    # retrun: [[wday, start, end], [wday, start, end], ...]
    #
    private
    def parse_period(str)
      ret = []
      str.lines do |line|
        next unless line =~ /^(\D+)([\d\-,]+)$/
        wday_ss = $1
        koma_ss = $2

        wday_ss.split("・").each do |wday_s|
          wday = WDAY_MAP[wday_s]

          # example: 4,5
          if koma_ss =~ /^[\d,s]+$/
            ret << parse_period_comma(wday, koma_ss)
          # example: 3-6
          elsif koma_ss =~ /^[\d\-]+$/
            ret << parse_period_hyphen(wday, koma_ss)
          end
        end
        ret.flatten!
      end
      ret
    end

    # カンマ区切りの曜時限をパース
    def parse_period_comma(wday, koma_ss)
      ret = []
      kstart = kend = 0

      koma_ss.split(",").map(&:to_i).each do |k|
        if kstart == 0
          kstart = kend = k
          next
        end

        if k == kend + 1
          kend = k
        else
          ret << { wday: wday, start: kstart, end: kend }
          kstart = kend = k
        end
      end
      ret.tap{|r| r << { wday: wday, start: kstart, end: kend } }
    end

    # ハイフン区切りの曜時限をパース
    def parse_period_hyphen(wday, koma_ss)
      kstart = koma_ss[0].to_i
      kend   = koma_ss[2].to_i
      { :wday => wday, :start => kstart, :end => kend }
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
    private
    def parse_term(str)
      ret = []
      str.lines do |line|
        line = "春ABC秋ABC" if line == "通年"

        if line.gsub!("夏季休業中", '')
          ret << { begin: TERM_BEGIN["夏"], end: TERM_END["夏"] }
        end

        rscan = line.strip.scan(/([春秋])([ABC]+)/)
        rscan.each do |item|
          term, mod = item

          mod = mod.split(//)
          begin_ = mod.first
          end_ = mod.last

          ret << { begin: TERM_BEGIN[term][begin_], end: TERM_END[term][end_] }
        end
      end
      ret
    end
  end
end
