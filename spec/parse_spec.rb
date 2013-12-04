#! /usr/bin/ruby
# coding: utf-8

require_relative '../functions.rb'

describe "Parse" do
  context "Jigen" do
    it "月・木2,3,5" do
      parse_jigen("月・木2,3,5").should == 
        [{:wday=>1, :start=>2, :end=>3},
         {:wday=>1, :start=>5, :end=>5},
         {:wday=>4, :start=>2, :end=>3},
         {:wday=>4, :start=>5, :end=>5}]
    end

    it "集中" do
      parse_jigen("集中").should == []
    end
  end

  context "Term" do

    it "夏季休業中春AB秋C" do
      parse_term("夏季休業中春AB秋C").should == 
        [{:begin=>"2013/08/13", :end=>"2013/09/30 13:00"},
         {:begin=>"2013/04/12", :end=>"2013/07/01 13:00"},
         {:begin=>"2013/12/23", :end=>"2014/02/07 13:00"}]
    end

    it "通年" do
      parse_term("通年").should == 
        [{:begin=>"2013/04/12", :end=>"2013/08/07 13:00"},
         {:begin=>"2013/10/01", :end=>"2014/02/07 13:00"}]
    end
  end
end
