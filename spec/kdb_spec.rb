#! /usr/bin/ruby
# coding: utf-8

require_relative '../lib/kdb.rb'
include KDB

describe "Parse" do
  context "Configuration" do
    before do
      @config = YAML.load_file(File.expand_path("../../config.yml", __FILE__))
    end

    describe "P" do
      describe "START" do
        it do
          expect(P_START).to eq(@config["P"]["START"])
        end
      end

      describe "END" do
        it do
          expect(P_END).to eq(@config["P"]["END"])
        end
      end
    end

    describe "TERM" do
      describe "BEGIN" do
        it "春A" do
          expect(TERM_BEGIN["春"]["A"]).to eq(@config["TERM"]["BEGIN"]["春"]["A"])
        end

        it "夏" do
          expect(TERM_BEGIN["夏"]).to eq(@config["TERM"]["BEGIN"]["夏"])
        end
      end

      describe "END" do
        it "春A" do
          expect(TERM_END["春"]["A"]).to eq(@config["TERM"]["END"]["春"]["A"])
        end

        it "夏" do
          expect(TERM_END["夏"]).to eq(@config["TERM"]["END"]["夏"])
        end
      end
    end
  end

  context "#initialize" do
    before do
      csv = File.open(File.expand_path("../m.csv", __FILE__), "r").read()
      @kdb = KDB::KDB.new(csv)
    end

    it do
      s = @kdb.subjects.first
      expect_period = [
        { wday: 5, start: 3, end: 3 }
      ]
      expect(s.period).to eq(expect_period)

      expect_term = [
        { begin: TERM_BEGIN["春"]["A"], end: TERM_END["春"]["B"] }
      ]
      expect(s.term).to eq(expect_term)
    end

    it do
      s = @kdb.subjects.second
      expect_period = [
        { wday: 4, start: 1, end: 2 }
      ]
      expect(s.period).to eq(expect_period)

      expect_term = [
        { begin: TERM_BEGIN["秋"]["A"], end: TERM_END["秋"]["B"] }
      ]
      expect(s.term).to eq(expect_term)
    end
  end

  context "#parse_period" do
    before(:all) do
      @kdb = KDB::KDB.new("")
    end
    context "when be separated by commas" do
      it "月4" do
        expect = [
          { wday: 1, start: 4, end: 4 },
        ]
        expect(@kdb.send(:parse_period, "月4")).to eq(expect)
      end

      it "月4,5" do
        expect = [
          { wday: 1, start: 4, end: 5 },
        ]
        expect(@kdb.send(:parse_period, "月4,5")).to eq(expect)
      end

      it "月・木2,3,5" do
        expect = [
          { wday: 1, start: 2, end: 3 },
          { wday: 1, start: 5, end: 5 },
          { wday: 4, start: 2, end: 3 },
          { wday: 4, start: 5, end: 5 }
        ]
        expect(@kdb.send(:parse_period, "月・木2,3,5")).to eq(expect)
      end

      it "月・木2,4,5" do
        expect = [
          { wday: 1, start: 2, end: 2 },
          { wday: 1, start: 4, end: 5 },
          { wday: 4, start: 2, end: 2 },
          { wday: 4, start: 4, end: 5 }
        ]
        expect(@kdb.send(:parse_period, "月・木2,4,5")).to eq(expect)
      end

      it "月・木2,3,5,6" do
        expect = [
          { wday: 1, start: 2, end: 3 },
          { wday: 1, start: 5, end: 6 },
          { wday: 4, start: 2, end: 3 },
          { wday: 4, start: 5, end: 6 },
        ]
        expect(@kdb.send(:parse_period, "月・木2,3,5,6")).to eq(expect)
      end
    end

    describe "when use a hyphen" do
      it "月・金3-6" do
        expect = [
          { wday: 1, start: 3, end: 6 },
          { wday: 5, start: 3, end: 6 },
        ]
      end
    end

    describe "when others" do
      it "集中" do
        expect(@kdb.send(:parse_period, "集中")).to eq([])
      end
    end
  end

  context "#parse_term" do
    before(:all) do
      @kdb = KDB::KDB.new("")
    end

    it "夏季休業中春AB秋C" do
      expect = [
        { begin: TERM_BEGIN["夏"], end: TERM_END["夏"] },
        { begin: TERM_BEGIN["春"]["A"], end: TERM_END["春"]["B"] },
        { begin: TERM_BEGIN["秋"]["C"], end: TERM_END["秋"]["C"] }
      ]
      expect(@kdb.send(:parse_term, "夏季休業中春AB秋C")).to eq(expect)
    end

    it "通年" do
      expect = [
        { begin: TERM_BEGIN["春"]["A"], end: TERM_END["春"]["C"] },
        { begin: TERM_BEGIN["秋"]["A"], end: TERM_END["秋"]["C"] }
      ]
      expect(@kdb.send(:parse_term, "通年")).to eq(expect)
    end
  end
end
