#! /usr/bin/ruby
# coding: utf-8

require 'cgi'
require 'erb'

class View

  def initialize(has_error)
    @has_error = has_error
  end

  extend ERB::DefMethod
  def_erb_method('to_html', 'views/index.erb')

end

begin
  cgi = CGI.new
  has_error = cgi.params["has_error"][0]

  # ビュー
  print cgi.header("charset"=>"UTF-8")
  print View.new(has_error).to_html

rescue => e
  # エラー処理
  exception_handling(e, cgi) 
end
