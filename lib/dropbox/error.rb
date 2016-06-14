require 'json'

module Dropbox
  class ClientError < StandardError
    attr_reader :message

    def self.unknown_response_type
      self.new("Unknown response type '#{str}'")
    end

    def initialize(message=nil)
      @message = message
    end

    def to_s
      @message.to_s
    end
  end

  class APIError < StandardError
    attr_reader :message

    def initialize(response)
      if response.content_type.mime_type == 'application/json'
        @message = JSON.parse(response)['error_summary']
      else
        @message = response
      end
    end

    def to_s
      @message.to_s
    end
  end
end
