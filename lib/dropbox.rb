module Dropbox
  class Client
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.new('Access token is invalid.')
      end

      @access_token = access_token
    end
  end

  class ClientError < StandardError
    attr_reader :message

    def initialize(message=nil)
      @message = message
    end

    def to_s
      @message.to_s
    end
  end
end
