require 'http'
require 'json'

module Dropbox
  class Client
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.invalid_access_token
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

    def download(path)
      resp, body = content_request('/download', path: path)
      return object_from_response(resp, 'file'), body
    end

    def get_metadata(path)
      resp = request('/get_metadata', path: path)
      object_from_response(resp)
    end

    def get_preview(path)
      resp, body = content_request('/get_preview', path: path)
      return object_from_response(resp, 'file'), body
    end

    def get_temporary_link(path)
      resp = request('/get_temporary_link', path: path)
      return object_from_response(resp['metadata'], 'file'), resp['link']
    end

    def get_thumbnail(path, format='jpeg', size='w64h64')
      resp, body = content_request('/get_thumbnail', path: path, format: format, size: size)
      return object_from_response(resp, 'file'), body
    end

    def list_folder(path)
      resp = request('/list_folder', path: path)
      resp['entries'].map { |e| object_from_response(e) }
    end

    def list_revisions(path)
      resp = request('/list_revisions', path: path)
      entries = resp['entries'].map { |e| object_from_response(e, 'file') }
      return entries, resp['is_deleted']
    end

    def move(from, to)
      resp = request('/move', from_path: from, to_path: to)
      object_from_response(resp)
    end

    def restore(path, rev)
      resp = request('/restore', path: path, rev: rev)
      object_from_response(resp, 'file')
    end

    def save_url(path, url)
      resp = request('/save_url', path: path, url: url)
      case resp['.tag']
      when 'complete'
        object_from_response(resp['complete'], 'file')
      when 'async_job_id'
        resp['async_job_id']
      else
        raise ClientError.unknown_response_type(resp['.tag'])
      end
    end

    def search(query, path='', max=100)
      resp = request('/search', path: path, query: query, max_results: max)
      resp['matches'].map { |m| object_from_response(m['metadata']) }
    end

    # Body can be a String or an Enumerable.
    # Mode can be 'add', 'overwrite', or 'update'.
    def upload(path, body, mode='add', autorename=false, client_modified=nil, mute=false)
      resp = upload_request('/upload', body, path: path, mode: mode,
        autorename: autorename, client_modified: client_modified, mute: mute)
      object_from_response(resp, 'file')
    end

    private
      def object_from_response(resp, tag=resp['.tag'])
        case tag
        when 'file'
          FileMetadata.new(resp['id'], resp['path_lower'], resp['size'],
            resp['client_modified'])
        when 'folder'
          FolderMetadata.new(resp['id'], resp['path_lower'])
        else
          raise ClientError.unknown_response_type(tag)
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

      def content_request(action, args = {})
        url = CONTENT_API + '/files' + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers('Dropbox-API-Arg' => args.to_json).get(url)
        raise APIError.new(resp) if resp.code != 200
        file = JSON.parse(resp.headers['Dropbox-API-Result'])
        return file, resp.body
      end

      def upload_request(action, body, args = {})
        url = CONTENT_API + '/files' + action
        headers = {'Content-Type' => 'application/octet-stream', 'Dropbox-API-Arg' => args.to_json}
        headers['Transfer-Encoding'] = 'chunked' unless body.is_a?(String)
        resp = HTTP.auth('Bearer ' + @access_token).headers(headers).post(url, body: body)
        raise APIError.new(resp) if resp.code != 200
        JSON.parse(resp.to_s)
      end
  end
end
