require 'http'
require 'json'

module Dropbox
  class Client
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.new('Access token is invalid.')
      end

      @access_token = access_token
    end

    def copy(from, to)
      resp = request('/copy', from_path: from, to_path: to)
      object_from_response(resp)
    end

    def create_folder(path)
      resp = request('/create_folder', path: path)
      FolderMetadata.new(resp['id'], resp['path_lower'])
    end

    def delete(path)
      resp = request('/delete', path: path)
      object_from_response(resp)
    end

    def list_folder(path)
      resp = request('/list_folder', path: path)
      resp['entries'].map { |e| object_from_response(e) }
    end

    def move(from, to)
      resp = request('/move', from_path: from, to_path: to)
      object_from_response(resp)
    end

    def search(query, path='', max=100)
      resp = request('/search', path: path, query: query, max_results: max)
      resp['matches'].map { |m| object_from_response(m['metadata']) }
    end

    private
      def object_from_response(resp)
        case resp['.tag']
        when 'file'
          FileMetadata.new(resp['id'], resp['path_lower'], resp['size'])
        when 'folder'
          FolderMetadata.new(resp['id'], resp['path_lower'])
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
end
