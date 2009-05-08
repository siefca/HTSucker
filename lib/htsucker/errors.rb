# encoding: utf-8
# 
# HTTP fetching class with limits and some heuristics
#
# Author::    Paweł Wilk (mailto:pw@gnu.org)
# Copyright:: Copyright (c) 2009 Paweł Wilk
# License::   LGPL
#
# ==Errors hierarchy
#
#   HTSuckerError                       # main handler for exceptions
#       HTSuckerSizeError               # size-related errors
#           HTSuckerContentTooBig       # content length > accepted length
#           HTSuckerContentOverflow     # read data > accepted length
#
#   HTSuckerConnectionFailed            # connection cannot be established
#       HTSuckerTooManyConnections      # connection attempts > conn_retry
#       HTSuckerTooManyRedirects        # redirects number > redir_retry
#       HTSuckerTimeout                 # timeout occured
#
#   HTSuckerBadURI                      # bad URI errors
#       HTSuckerMalformedURI            # malformed URI, e.g. empty string
#       HTSuckerBadProtocol             # bad protocol in URI
#       HTSuckerBadPort                 # bad port in URI
#       HTSuckerURIPhohibited           # prohibited URI, e.g. blacklisted
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

  class HTSuckerURIPhohibited < HTSuckerBadURI; end

  # This class handles exceptions caused by unsecure connection attempts.
  
  class HTSuckerPeerBlacklisted < HTSuckerBadURI; end

