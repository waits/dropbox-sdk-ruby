require_relative 'dropbox/client'
require_relative 'dropbox/errors'
require_relative 'dropbox/account'
require_relative 'dropbox/metadata'
require_relative 'dropbox/upload_session_cursor'

# A small library for accessing the new Dropbox API. All of the Dropbox API
# endpoints are implemented as methods on {Dropbox::Client}.
module Dropbox
  # The main API endpoint used for most calls.
  API = 'https://api.dropboxapi.com/2'.freeze

  # The content API endpoint used for upload/download calls.
  CONTENT_API = 'https://content.dropboxapi.com/2'.freeze
end
