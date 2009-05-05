# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL

require 'iconv'
require 'htmlentities'
require 'net/http'
require 'net/https'
require 'timeout'
require 'uri'

require 'resolv'
require 'ipaddr'
require 'open-uri'

require 'bufferaffects'
require '/htsucker/domains_to_languages'
require '/htsucker/errors'
require '/htsucker/htsucker'

## testing:
#
#sites = []
#sites << 'wykop.pl'
#sites << 'poland.com'
#sites << 'hyperreal.info'
#sites << 'grono.net'
#sites << 'google.pl'
#sites << 'randomseed.pl'
#sites << 'heise-online.de'
#
#sites.each do |site|
#  pa = HTSucker.new(site, :ignore_content_overflows => true)
#  puts "#{pa.real_url}: #{pa.language} #{pa.charset}"
#end
