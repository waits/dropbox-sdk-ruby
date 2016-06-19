require 'http'
require 'json'
require 'time'

module Dropbox
  class Client
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.invalid_access_token
      end

      @access_token = access_token
    end

    def copy(from, to)
      resp = request('/files/copy', from_path: from, to_path: to)
      parse_tagged_response(resp)
    end

    def create_folder(path)
      resp = request('/files/create_folder', path: path)
      parse_tagged_response(resp, 'folder')
    end

    def delete(path)
      resp = request('/files/delete', path: path)
      parse_tagged_response(resp)
    end

    def download(path)
      resp, body = content_request('/files/download', path: path)
      return parse_tagged_response(resp, 'file'), body
    end

    def get_account(id)
      resp = request('/users/get_account', account_id: id)
      parse_tagged_response(resp, 'basic_account')
    end

    def get_account_batch(ids)
      resp = request('/users/get_account_batch', account_ids: ids)
      resp.map { |a| parse_tagged_response(a, 'basic_account') }
    end

    def get_current_account
      resp = request('/users/get_current_account')
      parse_tagged_response(resp, 'full_account')
    end

    def get_metadata(path)
      resp = request('/files/get_metadata', path: path)
      parse_tagged_response(resp)
    end

    def get_preview(path)
      resp, body = content_request('/files/get_preview', path: path)
      return parse_tagged_response(resp, 'file'), body
    end

    def get_temporary_link(path)
      resp = request('/files/get_temporary_link', path: path)
      return parse_tagged_response(resp['metadata'], 'file'), resp['link']
    end

    def get_thumbnail(path, format='jpeg', size='w64h64')
      resp, body = content_request('/files/get_thumbnail', path: path, format: format, size: size)
      return parse_tagged_response(resp, 'file'), body
    end

    def list_folder(path)
      resp = request('/files/list_folder', path: path)
      resp['entries'].map { |e| parse_tagged_response(e) }
    end

    def list_revisions(path)
      resp = request('/files/list_revisions', path: path)
      entries = resp['entries'].map { |e| parse_tagged_response(e, 'file') }
      return entries, resp['is_deleted']
    end

    def move(from, to)
      resp = request('/files/move', from_path: from, to_path: to)
      parse_tagged_response(resp)
    end

    def restore(path, rev)
      resp = request('/files/restore', path: path, rev: rev)
      parse_tagged_response(resp, 'file')
    end

    # Revokes the current access token and returns it
    def revoke_token
      r = HTTP.auth('Bearer ' + @access_token).post(API + '/auth/token/revoke')
      raise APIError.new(r) if r.code != 200
      @access_token
    end

    def save_url(path, url)
      resp = request('/files/save_url', path: path, url: url)
      case resp['.tag']
      when 'complete'
        parse_tagged_response(resp['complete'], 'file')
      when 'async_job_id'
        resp['async_job_id']
      else
        raise ClientError.unknown_response_type(resp['.tag'])
      end
    end

    def search(query, path='', max=100)
      resp = request('/files/search', path: path, query: query, max_results: max)
      resp['matches'].map { |m| parse_tagged_response(m['metadata']) }
    end

    # Body can be a String or an Enumerable
    # Mode can be 'add', 'overwrite', or 'update'
    def upload(path, body, mode='add', autorename=false, client_modified=nil, mute=false)
      client_modified = client_modified.iso8601 if client_modified.is_a?(Time)
      resp = upload_request('/files/upload', body, path: path, mode: mode,
        autorename: autorename, client_modified: client_modified, mute: mute)
      parse_tagged_response(resp, 'file')
    end

    private
      def parse_tagged_response(resp, tag=resp['.tag'])
        case tag
        when 'file'
          FileMetadata.new(resp)
        when 'folder'
          FolderMetadata.new(resp)
        when 'deleted'
          DeletedMetadata.new(resp)
        when 'basic_account'
          BasicAccount.new(resp)
        when 'full_account'
          FullAccount.new(resp)
        else
          raise ClientError.unknown_response_type(tag)
        end
      end

      def request(action, data=nil)
        url = API + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers(content_type: ('application/json' if data))
          .post(url, json: data)

        raise APIError.new(resp) if resp.code != 200
        JSON.parse(resp.to_s)
      end

      def content_request(action, args={})
        url = CONTENT_API + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers('Dropbox-API-Arg' => args.to_json).get(url)

        raise APIError.new(resp) if resp.code != 200
        file = JSON.parse(resp.headers['Dropbox-API-Result'])
        return file, resp.body
      end

      def upload_request(action, body, args={})
        resp = HTTP.auth('Bearer ' + @access_token).headers({
          'Content-Type' => 'application/octet-stream',
          'Dropbox-API-Arg' => args.to_json,
          'Transfer-Encoding' => ('chunked' unless body.is_a?(String))
        }).post(CONTENT_API + action, body: body)

        raise APIError.new(resp) if resp.code != 200
        JSON.parse(resp.to_s)
      end
  end
end
