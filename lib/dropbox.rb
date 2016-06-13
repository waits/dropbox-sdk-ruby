require 'http'
require 'json'

module Dropbox
  API = 'https://api.dropboxapi.com/2'

  class Client
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.new('Access token is invalid.')
      end

      @access_token = access_token
    end

    def create_folder(path)
      resp = request('/create_folder', path: path)
      Folder.new(resp['id'], resp['path_lower'])
    end

    def delete(path)
      resp = request('/delete', path: path)
      object_from_response(resp)
    end

    def list_folder(path)
      resp = request('/list_folder', path: path)
      resp['entries'].map { |e| object_from_response(e) }
    end

    private
      def object_from_response(resp)
        case resp['.tag']
        when 'file'
          File.new(resp['id'], resp['path_lower'], resp['size'])
        when 'folder'
          Folder.new(resp['id'], resp['path_lower'])
        else
          raise ClientError.new('Unknown response type')
        end
      end

      def request(action, data = {})
        url = API + '/files' + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers(content_type: 'application/json')
          .post(url, json: data)
        raise APIError.new(resp) if resp.code != 200
        JSON.parse(resp.to_s)
      end
  end

  class Object
    attr_reader :id, :path, :name

    def initialize(id, path)
      @id = id
      @path = path
      @name = path.split('/').last
    end
  end

  class File < Object
    attr_reader :size

    def initialize(id, path, size)
      @size = size
      super(id, path)
    end
  end

  class Folder < Object
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
