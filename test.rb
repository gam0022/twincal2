#! /usr/bin/ruby
# coding: utf-8

require_relative 'functions.rb'

str = "月・木2,3,5"
#str = "集中"
p parse_jigen(str)

str = "夏季休業中春AB秋C"
str = "通年"
p parse_term(str)
