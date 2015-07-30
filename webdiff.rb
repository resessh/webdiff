#!/Users/01023069/.rbenv/shims/ruby
# coding: utf-8

require 'open-uri'
require 'diff/lcs'

require "./class.rb"
require "./HOSTINFO.rb"

pass = ARGV[0]

fl = FileList.new( pass )
fl.checkFilesDiff