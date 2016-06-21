require 'http'
require 'json'
require 'time'

module Dropbox
  # Client contains all the methods that map to the Dropbox API endpoints.
  class Client
    # Initialize a new client.
    #
    # @param [String] access_token
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.invalid_access_token
      end

      @access_token = access_token
    end

    # Copy a file or folder to a different location in the user's Dropbox.
    #
    # @param [String] from_path
    # @param [String] to_path
    # @return [Dropbox::Metadata]
    def copy(from_path, to_path)
      resp = request('/files/copy', from_path: from_path, to_path: to_path)
      parse_tagged_response(resp)
    end

    # Create a folder at a given path.
    #
    # @param [String] path
    # @return [Dropbox::FolderMetadata]
    def create_folder(path)
      resp = request('/files/create_folder', path: path)
      FolderMetadata.new(resp)
    end

    # Delete the file or folder at a given path.
    #
    # @param [String] path
    # @return [Dropbox::Metadata]
    def delete(path)
      resp = request('/files/delete', path: path)
      parse_tagged_response(resp)
    end

    # Download a file from a user's Dropbox.
    #
    # @param [String] path
    # @return [Dropbox::FileMetadata] metadata
    # @return [HTTP::Response::Body] body
    def download(path)
      resp, body = content_request('/files/download', path: path)
      return FileMetadata.new(resp), body
    end

    # Get information about a user's account.
    #
    # @param [String] account_id
    # @return [Dropbox::BasicAccount]
    def get_account(account_id)
      resp = request('/users/get_account', account_id: account_id)
      BasicAccount.new(resp)
    end

    # Get information about multiple user accounts.
    #
    # @param [Array<String>] account_ids
    # @return [Array<Dropbox::BasicAccount>]
    def get_account_batch(account_ids)
      resp = request('/users/get_account_batch', account_ids: account_ids)
      resp.map { |a| BasicAccount.new(a) }
    end

    # Get information about the current user's account.
    #
    # @return [Dropbox::FullAccount]
    def get_current_account
      resp = request('/users/get_current_account')
      FullAccount.new(resp)
    end

    # Get the metadata for a file or folder.
    #
    # @param [String] path
    # @return [Dropbox::Metadata]
    def get_metadata(path)
      resp = request('/files/get_metadata', path: path)
      parse_tagged_response(resp)
    end

    # Get a preview for a file.
    #
    # @param [String] path
    # @return [Dropbox::FileMetadata] metadata
    # @return [HTTP::Response::Body] body
    def get_preview(path)
      resp, body = content_request('/files/get_preview', path: path)
      return FileMetadata.new(resp), body
    end

    # Get the space usage information for the current user's account.
    #
    # @return [Dropbox::SpaceUsage]
    def get_space_usage
      resp = request('/users/get_space_usage')
      SpaceUsage.new(resp)
    end

    # Get a temporary link to stream content of a file.
    #
    # @param [String] path
    # @return [Dropbox::FileMetadata] metadata
    # @return [String] link
    def get_temporary_link(path)
      resp = request('/files/get_temporary_link', path: path)
      return FileMetadata.new(resp['metadata']), resp['link']
    end

    # Get a thumbnail for an image.
    #
    # @param [String] path
    # @param [String] format
    # @param [String] size
    # @return [Dropbox::FileMetadata] metadata
    # @return [HTTP::Response::Body] body
    def get_thumbnail(path, format='jpeg', size='w64h64')
      resp, body = content_request('/files/get_thumbnail', path: path, format: format, size: size)
      return FileMetadata.new(resp), body
    end

    # Get the contents of a folder.
    #
    # @param [String] path
    # @return [Array<Dropbox::Metadata>]
    def list_folder(path)
      resp = request('/files/list_folder', path: path)
      resp['entries'].map { |e| parse_tagged_response(e) }
    end

    # Get the revisions of a file.
    #
    # @param [String] path
    # @return [Array<Dropbox::FileMetadata>] entries
    # @return [Boolean] is_deleted
    def list_revisions(path)
      resp = request('/files/list_revisions', path: path)
      entries = resp['entries'].map { |e| FileMetadata.new(e) }
      return entries, resp['is_deleted']
    end

    # Move a file or folder to a different location in the user's Dropbox.
    #
    # @param [String] from_path
    # @param [String] to_path
    # @return [Dropbox::Metadata]
    def move(from_path, to_path)
      resp = request('/files/move', from_path: from_path, to_path: to_path)
      parse_tagged_response(resp)
    end

    # Restore a file to a specific revision.
    #
    # @param [String] path
    # @param [String] rev
    # @return [Dropbox::FileMetadata]
    def restore(path, rev)
      resp = request('/files/restore', path: path, rev: rev)
      FileMetadata.new(resp)
    end

    # Disable the access token used to authenticate the call.
    #
    # @return [void]
    def revoke_token
      r = HTTP.auth('Bearer ' + @access_token).post(API + '/auth/token/revoke')
      raise APIError.new(r) if r.code != 200
    end

    # Save a specified URL into a file in user's Dropbox.
    #
    # @param [String] path
    # @param [String] url
    # @return [String] the job id, if the processing is asynchronous.
    # @return [Dropbox::FileMetadata] if the processing is synchronous.
    def save_url(path, url)
      resp = request('/files/save_url', path: path, url: url)
      case resp['.tag']
      when 'complete'
        FileMetadata.new(resp['complete'])
      when 'async_job_id'
        resp['async_job_id']
      else
        raise ClientError.unknown_response_type(resp['.tag'])
      end
    end

    # Search for files and folders.
    #
    # @param [String] query
    # @param [String] path
    # @param [Integer] max_results
    # @return [Array<Dropbox::Metadata>] matches
    def search(query, path='', max_results=100)
      resp = request('/files/search', path: path, query: query, max_results: max_results)
      resp['matches'].map { |m| parse_tagged_response(m['metadata']) }
    end

    # Create a new file.
    #
    # @param [String] path
    # @param [String, Enumerable] body
    # @param [String] mode
    # @param [Boolean] autorename
    # @param [String, Time] client_modified
    # @param [Boolean] mute
    # @return [Dropbox::FileMetadata]
    def upload(path, body, mode='add', autorename=false, client_modified=nil, mute=false)
      client_modified = client_modified.iso8601 if client_modified.is_a?(Time)
      resp = upload_request('/files/upload', body, path: path, mode: mode,
        autorename: autorename, client_modified: client_modified, mute: mute)
      FileMetadata.new(resp)
    end

    private
      def parse_tagged_response(resp)
        case resp['.tag']
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
          raise ClientError.unknown_response_type(resp['.tag'])
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
