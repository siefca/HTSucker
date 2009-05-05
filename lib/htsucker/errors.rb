# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL
#
# This is the main exception handling class for HTSucker.

class HTSuckerError < Exception; end

# This class handles size-related errors.

class HTSuckerSizeError < HTSuckerError; end

  # This class handles exceptions caused by Content-Length exceeding declared limit.

  class HTSuckerContentTooBig < HTSuckerSizeError; end

  # This class handles exceptions caused by readed data exceeding declared limit.

  class HTSuckerContentOverflow < HTSuckerSizeError; end

# This class handles exceptions caused by too many failed connection attempts.

class HTSuckerConnectionFailed < HTSuckerError; end

  # This class handles exceptions caused by too many failed connection attempts.

  class HTSuckerTooManyConnections < HTSuckerConnectionFailed; end

  # This class handles exceptions caused by too many redirects.

  class HTSuckerTooManyRedirects < HTSuckerConnectionFailed; end

  # This class handles exceptions caused by timeout while reading data.

  class HTSuckerTimeout < HTSuckerConnectionFailed; end

# This class handles exceptions caused by bad URIs.

class HTSuckerBadURI < HTSuckerError; end

  # This class handles exceptions caused by malformed URIs.

  class HTSuckerMalformedURI < HTSuckerBadURI; end

  # This class handles exceptions caused by bad protocol in URI.

  class HTSuckerBadProtocol < HTSuckerBadURI; end

  # This class handles exceptions caused by strange port number in URI.

  class HTSuckerBadPort < HTSuckerBadURI; end

  # This class handles exceptions caused by unsecure redirect attempts.

  class HTSuckerRedirectPhohibited < HTSuckerBadURI; end

