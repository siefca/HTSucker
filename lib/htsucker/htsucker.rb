# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL

class HTSucker

  include DomainsToLanguages
  include BufferAffects

  buffers_reset_method  :reset_buffers
  attr_affects_buffers  :url
  
  attr_reader :url
  
  # Default options are matrix for defaults used by class method HTSucker.default_options
  # while setting up class variable @@default_options which is used by instances as a
  # matrix for options not given when creating new objects.
  
  DefaultOpts = { :redir_retry              => 5,
                  :conn_retry               => 8,
                  :total_retry              => 2,
                  :read_timeout             => 15,
                  :total_timeout            => 30,
                  :default_content_lanuage  => 'en',
                  :default_content_type     => 'text/html',
                  :default_charset          => 'iso-8859-1',
                  :allow_strange_ports      => false,
                  :ignore_content_overflows => false,
                  :max_length               => 524288 }.freeze
  
  attr_reader *DefaultOpts.keys
  
  # Creates new instance of HTSucker. +url+ parameter should be valid URI object or string.
  # You may want to override defaults by issuing hash containing options you want to be changed.
  
  def initialize(url, options=nil)
    default_options = self.class.default_options.dup
    if options.respond_to?(:keys)
      unknown = (options.keys - default_options.keys).join(', ')
      raise ArgumentError.new("unknown options: #{unknown}") unless unknown.empty?
      default_options.merge!(options)
    end
    default_options.each_pair do |opt_name,opt_value|
      instance_variable_set("@#{opt_name}", opt_value)
    end
    reset_buffers
    self.url = url
  end
  
  # Resets charset and response buffers.
  
  def reset_buffers
    @charset      = nil
    @content_type = nil
    @response     = nil
    @real_url     = nil
    @body         ||= ""
    @header       ||= {}
    @body.replace ""
    @header.clear
  end
  
  # Sets new url.
  
  def url=(url)
    url = URI.parse(url) unless url.kind_of?(URI)
    url = URI.parse("http://#{url.to_s}") if url.is_a?(URI::Generic) 
    url.path = '/' if url.path.nil? || url.path.empty?
    validate_url(url)
    @url = url
    @url.freeze
  end
  
  # Returns top-level domain for URL.
  
  def domain
    self.url.host.split('.').last.downcase.to_sym
  end
  
  # Returns top-level domain for real URL.
  
  def real_domain
    self.real_url.host.split('.').last.downcase.to_sym
  end
  
  # Returns resource path.
  def path; url.path end
  
  # Returns real resource path.
  def real_path; real_url.path end
  
  # Returns hostname.
  def host; url.host end
  
  # Returns real hostname.
  def real_host; real_url.host end
  
  # Returns used port.
  def port; url.port end

  # Returns real port.
  def real_port; real_url.port end
  
  # Returns protocol.
  def protocol; url.scheme.downcase.to_sym end
  
  # Returns real protocol.
  def real_protocol; real_url.scheme.downcase.to_sym end

  # Returns page charset.

  def charset
    @content_type, @charset = get_page_info if @charset.nil?
    return @charset
  end
  
  def content_charset;     charset      end
  def content_charset=(x)  charset=(x)  end

  # Returns page content-type.

  def content_type
    @content_type, @charset = get_page_info if @content_type.nil?
    return @content_type
  end
  
  # Returns major name of the content-type or nil if something went wrong.
  
  def content_type_major
    ctype = self.content_type.to_s
    return nil if ctype.empty?
    ctype = ctype.split('/').first
    return nil if ctype.to_s.empty?
    return ctype.to_sym
  end
  
  # Returns minor name of the content-type or nil if something went wrong.
  
  def content_type_minor
    ctype = content_type.to_s
    return nil if ctype.empty?
    ctype = ctype.split('/')[1]
    return nil if ctype.to_s.empty?
    return ctype.to_sym
  end
  
  def validate_url(url)
    raise HTSuckerMalformedURI.new("malformed URI") if url.to_s.empty?
    u_protocol = url.scheme.downcase.to_sym
    unless [:http,:https].include?(u_protocol)
      raise HTSuckerBadProtocol.new("bad protocol: #{u_protocol}")
    end
    unless @allow_strange_ports
      if ((u_protocol == :http  && url.port != 80) ||
          (u_protocol == :https && url.port != 443))
        raise HTSuckerBadPort.new("strange port number: #{url.port}")
      end
    end
  end
  private :validate_url
  
  def validate_redirect(url1, url2)
    if url1.scheme.downcase != url2.scheme.downcase
      raise HTSuckerRedirectProhibited.new("redirect prohibited: #{url1} -> #{url2}")
    end
  end
  private :validate_redirect
  
  # Translates top-level domain to spoken language code.
  
  def domain_to_spoken
    lang = nil
    enc = content_charset.to_s[0..2].downcase.to_sym
    national_encodings = [:iso, :win, :"cp-", :koi, :utf]
    if national_encodings.include?(enc) 
      lang = @@domain_to_language[self.real_domain] if real_domain.length == 2
    end
    return lang
  end
  private :domain_to_spoken
  
  # This method returns +true+ if page is declared by server to be in some text format.
  
  def text_content?
    header = @header[:"content-type"]
    extract_content_type(header).to_s.split('/').first == 'text'
  end
  private :text_content?
  
  # Returns content-language or default content language.
  
  def content_language(default_content_lanuage=nil)
    default_content_lanuage ||= @default_content_lanuage
    clang = nil
    prepare_response
    
    # try meta-tag header
    unless (@body.to_s.empty? || !text_content?)
      header  = @body.scan(/<meta http-equiv\s*=\s*['"]*content-language['"]*\s*content\s*=\s*['"]*\s*(.*?)\s*['"]*\s*\/?>/i)
      header  = header.flatten.first
      clang   = extract_content_language(header)
    end
    
    # try lang and xml:lang attribute from HTML tag and do the same for body tag
    if (clang.to_s.empty? && !@body.to_s.empty? && text_content?)
      header  = @body.scan(/<x?html\s.*?\s+?lang\s*?=["']*([^"']+).*?\/?>/i)
      header  = header.flatten.first
      if header.to_s.empty?
        header  = @body.scan(/<x?html\s.*?\s+?xml:lang\s*?=["']*([^"']+).*?\/?>/i)
        header  = header.flatten.first
      end
      if header.to_s.empty?
        header  = @body.scan(/<body\s.*?\s+?lang\s*?=["']*([^"']+).*?\/?>/i)
        header  = header.flatten.first
      end
      if header.to_s.empty?
        header  = @body.scan(/<body\s.*?\s+?xml:lang\s*?=["']*([^"']+).*?\/?>/i)
        header  = header.flatten.first
      end
      clang = extract_content_language(header)
    end

    # try server header and in case of 'en' or empty try to figure language by looking at top-domain
    if clang.to_s.empty?
      header  = @header[:"content-language"]
      clang   = extract_content_language(header)
      present = clang.to_s
      clang   = domain_to_spoken if (present.empty? || present[0..1] == 'en')
      clang   = present if (clang.to_s.empty? && !present.empty?)
    end
    
    # try default
    clang = default_content_lanuage if clang.to_s.empty?
    
    return clang
  end
  
  def language; content_language end
  def lang;     content_language end

  # Obtains charset from document body or server response header.

  def get_page_info(default_content_type=nil, default_charset=nil)
    default_content_type  ||= @default_content_type
    default_charset       ||= @default_charset
    
    # try meta-tag header
    enc     = nil
    ctype   = nil
    
    # try server header first time to see if we even can analyze the content
    
    unless (@body.to_s.empty? || !text_content?)
      header  = @body.scan(/<meta http-equiv\s*=\s*['"]*content-type['"]*\s*content\s*=\s*['"]*\s*(.*?)\s*['"]*\s*\/?>/i)
      header  = header.flatten.first
      enc     = extract_charset(header)
      ctype   = extract_content_type(header)
    end
    
    # try server header
    if ctype.to_s.empty?
      header  = @header[:"content-type"]
      ctype   = extract_content_type(header)
      enc     = extract_charset(header) if enc.to_s.empty? # weird but may happend (page with charset encoding but without type)
    end
    
    # try defaults
    enc   = default_charset       if enc.to_s.empty?
    ctype = default_content_type  if ctype.to_s.empty?

    return [ctype, enc]
  end
  private :get_page_info

  # Extracts charset from content-type string.

  def extract_charset(enc_string)
    return nil if (enc_string.nil? || enc_string.empty?)
    ret_enc = nil
    ct = enc_string.chomp.downcase.squeeze(' ')

    unless ct.nil?
      ctary = {}
      ct.split(';').each do |segment|
        k,v = segment.split('=')
        ctary[k.strip.to_sym] = v unless (k.nil? || v.nil?)
      end
      if ctary.has_key?(:charset)
        begin
          test_enc = ctary[:charset]
          test_enc = 'utf-8' if test_enc == 'utf8'
          ret_enc = Encoding.find(test_enc)
          ret_enc = ret_enc.name
        rescue ArgumentError
        end
      end
    end

    ret_enc = nil if (ret_enc.nil? || ret_enc.squeeze(" ").empty?)
    return ret_enc.to_s.downcase.to_sym
  end
  private :extract_charset

  # Extracts content-type from content-type string.

  def extract_content_type(ctype_string)
    return nil if ctype_string.to_s.empty?
    ct = ctype_string.chomp.squeeze(' ').split(';').first
    ct = ct.strip.downcase.to_sym unless ct.nil?
    return ct
  end
  private :extract_content_type

  # Extracts content-language from content-language string.

  def extract_content_language(ltype_string)
    return nil if ltype_string.to_s.empty?
    lt = ltype_string.chomp.squeeze(' ').split(';').first.split(',').first
    lt = lt.strip.downcase.to_sym unless lt.nil?
    return lt
  end
  private :extract_content_language

  # Creates resource for given HTTP or HTTPS URI.
  
  def http_resource(url)
    res = Net::HTTP.new(url.host, url.port)
    case url.scheme.downcase.to_sym
    when :http
      return res
    when :https
      res.use_ssl     = true
      res.verify_mode = OpenSSL::SSL::VERIFY_NONE
    else
      raise HTSuckerBadProtocol("unknown protocol #{url.scheme}")
    end
    return res
  end
  private :http_resource
  
  # This method fetches response from HTTP object and marks it in @response
  # instance variable. It also fills up @header hash and @body. It controls
  # number of bytes read and raises error if the value is exceeded.
  
  def fetch_response(url, max=nil)
    max_length = max.nil? ? @max_length : max
    char_oriented = String.instance_methods.include?(:bytesize)
    length_bytes = 0
    @body.replace ""
    @header.clear
    
    max_length = max_length.to_s.to_i
    http_req = Net::HTTP::Get.new(url.path)
    http = http_resource(url)
    
    begin
      http.start do
        resp = http.request(http_req) do |resp|
          @response = resp
          @response.each { |k,v| @header[k.downcase.to_sym] = v }
          @response.value
          header_length = @header[:"content-length"].to_s.to_i
          if !max_length.zero? && header_length > max_length
            raise HTSuckerContentTooBig.new("content length (#{header_length}) is bigger than #{max_length} bytes")
          end
          @response.read_body do |segment|
            segment_bytes = char_oriented ? segment.bytesize : segment.size
            length_bytes += segment_bytes
            if !max_length.zero? && length_bytes > max_length
              @body << segment[0..max_length-length_bytes-1]
              length_bytes = max_length
              raise HTSuckerContentOverflow.new("read data size exceeds #{max_length} bytes, aborting")
            else
              @body << segment
            end
          end # response.read_body
        end # http.request
      end # http.start
    ensure
      http.finish if http.started?
    end
    return @response
  end
  private :fetch_response
  
  # This method fetches response through fetch_response and manages retries and connection errors.
  
  def response_do(max=nil)
    url         = @url
    @real_url   = nil
    redir_retry = @redir_retry
    conn_retry  = @conn_retry
      
    begin
      fetch_response(url, max)
      
    rescue Net::HTTPRetriableError, Net::ProtoRetriableError, IOError, SystemCallError
      unless @header[:location].to_s.empty?
        raise HTSuckerTooManyRedirects.new("too many redirects") if redir_retry <= 0
        dest_url = URI.parse(@header[:location])          
        validate_redirect(url, dest_url)
        validate_url(dest_url)
        url = dest_url
        redir_retry -= 1
      else
        raise HTSuckerTooManyConnections.new($!.to_s) if conn_retry <= 0
        conn_retry -= 1
        Kernel.sleep(1)
      end
      retry
      
    rescue HTSuckerSizeError
      raise unless @ignore_content_overflows
      
    rescue RuntimeError, Net::ProtocolError, Net::HTTPClientError, Net::HTTPServerError, Net::HTTPUnknownResponse
      raise HTSuckerConnectionFailed.new($!.to_s)  
    
    end
    
    @real_url = url
  end
  private :response_do
  
  # Fetches document and headers using HTTP if they are not fetched yet. It also manages timeout.
  
  def prepare_response(max=nil)
    return unless @response.nil?
    begin
      Timeout::timeout(@timeout) { response_do(max) }
    rescue Timeout::Error
      raise HTSuckerTimeout.new($!.to_s) 
    end
  end
  private :prepare_response
  
  # Returns document body.
  
  def body(*args)
    prepare_response(*args)
    return @body
  end
  
  alias_method :fetch, :body
  alias_method :suck,  :body
  
  # Returns server headers.
  
  def header(*args)
    prepare_response(*args)
    return @header
  end
  
  # Returns URL used while obtaining content (e.g. after redirection).
  
  def real_url
    prepare_response
    return @real_url
  end
  
  # Strips HTML tags from document.

  def strip_html(text=nil)
    text    ||= self.body
    @coder  ||= HTMLEntities.new
    r = text.tr("\t", ' ')
    r.tr!("\r", '')
    r.sub!(%r{<body.*?>(.*?)</body>}mi, '\1')
    r.gsub!(%r{<script.*?>(.*?)</script>}mi, ' ')
    r.gsub!(%r{<style.*?>(.*?)</style>}mi, ' ')
    r.gsub!(%r{<!--.*?-->}mi, ' ')
    r.gsub!(/<br\s*\/?>|<p>/mi, "\n")
    r.gsub!(/<.*?>/m, '')
    return coder.decode(r)
  end

  # Transliterates text to ASCII and removes unknown characters.

  def clean_text(text=nil, enc=nil)
    text            ||= self.body
    enc             ||= self.charset
    @transliterator ||= Iconv.new('ASCII//TRANSLIT//IGNORE', 'UTF-8')
    page = Iconv.iconv('UTF-8//IGNORE', enc, text).join
    page = strip_html(page)
    page.gsub!(/['`]/m, '_amp__')
    page = @transliterator.conv(page).downcase
    page.tr!(".!?", ' ')
    page.gsub!(/[^\x00-\x7F]+/, '')
    page.gsub!(/[^a-z0-9\-_\[\]\(\)\*\=\@\#\$\%\^\&\{\}\:\;\,\<\>\+\s\n\.\!\?]+/im, '')
    page.gsub!('_amp__',"'")
    page.squeeze!(" \n")
    page.gsub!(/^\s?\n\s?$/m, '')
    page.gsub!(/\n\s/,"\n")
    page.gsub!(/\s\n/,"\n")
    page.gsub!(/^\s+/,'')
    page.gsub!(/(^|\s)\'+(.*?)\'+(\s|$)/m,'\1\2\3')
    page.gsub!(/(^|\s)\'+(\s|$)/, '')
    page.squeeze!("\n ")
    return page
  end
  
  def clean; clean_text end

  # Transliterates text to ASCII and removes unknown characters leaving just words.
  
  def clean_words(text=nil, enc=nil)
    cw = clean_text(text, enc)
    cw.gsub!(/\[\s*?[^\:]+?\:\/+?.*?\]/mi, ' ')
    cw.gsub!(/\[\s*?(\d|\s|[^\w])+\]/mi, ' ')
    cw.gsub!(/[^a-z0-9]+/im, ' ')
    cw.squeeze!(' ')
    return cw
  end
  
  # Transliterates text to ASCII, removes unknown characters and returns array of words.
  
  def words
    self.clean_words.split(' ')
  end
  
  # Use this class method to set up default options used when creating new objects.
  # For each option that you omit it will be taken from constant hash called DefaultOpts.
  # Default options hash is stored in @@default_options. This method will return current
  # default options when called without parameter.
  
  def self.default_options(opts=nil)
    @@default_options ||= DefaultOpts.dup
    return @@default_options.freeze if opts.nil?
    if opts.respond_to?(:keys)
      known_opts = DefaultOpts.keys
      unknown = (opts.keys - known_opts).join(', ')
      raise ArgumentError.new("unknown options: #{unknown}") unless unknown.empty?
      @@default_options.unfreeze
      @@default_options.merge!(opts)
      return @@default_options.freeze
    else
      raise ArgumentError.new("malformed options")
    end
  end
  
  # This class method helps to build white- and blacklists for IP addresses.
  
  def self.ip_list(storage, list)
    storage ||= []
    return storage if list.nil?
    storage = list.map {|a| a.is_a?(IPAddr) ? a.freeze : IPAddr.new(a.to_s)}
  end
  private_class_method :ip_list
  
  # This class method lets you define whitelist of IP addresses. If this list is set
  # then these addresses will be used by all HTSucker objects while checking URIs.
  # This list has meaning when blacklist is also set – it simply allows to create
  # exceptions from rules present there. It uses default resolver to
  # obtain IP addresses for DNS names used as hostnames.
  #
  # The list should be an array of strings or symbols, which will be changed to IPAddr
  # objects. They may be single IPs or netmasks. Example: +ip_whitelist 192.168.0.0/16+
  
  def self.ip_whitelist(list=nil)
    ip_list @@ip_whitelist, list
  end

  # This class method lets you define blacklist of IP addresses. If this list is set
  # then these addresses will be used by all HTSucker objects while checking URIs.
  # It contains addresses that HTSucker will refuse to handle and throw an exception
  # if you or some redirect will try to use them. It uses default resolver to
  # obtain IP addresses for DNS names used as hostnames.
  #
  # The list should be an array of strings or symbols, which will be changed to IPAddr
  # objects. They may be single IPs or netmasks. Example: +ip_whitelist 192.168.0.0/16+
  
  def self.ip_blacklist(list=nil)
    ip_list @@ip_blacklist, list
  end
  
  def self.host_whitelist
  end
  
  def self.host_blacklist
  end
  
end

