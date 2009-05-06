# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL
#
# HTSucker is a class that provides an easy way of obtaining documents from the web.
# It follows redirects and allows you to set up various connection parameters like
# size limits and timeouts.
# 
# It is intended to be used in programs getting some information about web pages
# and processing resources that aren’t too big, since it keeps all data in memory.
# 
# HTSucker tries to figure out content's language using server headers, HTML tags,
# code markers, and if fails it then uses top-level domain name to spoken
# language mapping. It doesn't use any XML object model to access (X)HTML tags
# but relies on regular expressions.
# 
# All operations are lazy, which means that after creating an object you will
# still be able to change some connection parameters. Real data fetching will occur
# while accessing body, headers or other data that requires network access. This class
# uses net/http module.

require 'resolv'
require 'ipaddr'

require 'net/http'
require 'net/https'
require 'timeout'
require 'uri'

require 'iconv'
require 'htmlentities'

require 'bufferaffects'
require 'htsucker/domains_to_languages'
require 'htsucker/errors'
require 'htsucker/htsucker'

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
