require 'http'
require 'json'
require 'time'

module Dropbox
  # Client contains all the methods that map to the Dropbox API endpoints.
  class Client
    # @param [String] access_token
    def initialize(access_token)
      unless access_token =~ /^[a-z0-9_-]{64}$/i
        raise ClientError.invalid_access_token
      end

      @access_token = access_token
    end

    # Disable the access token used to authenticate the call.
    #
    # @return [void]
    def revoke_token
      r = HTTP.auth('Bearer ' + @access_token).post(API + '/auth/token/revoke')
      raise ApiError.new(r) if r.code != 200
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

    # Get a copy reference to a file or folder.
    #
    # @param [String] path
    # @return [Dropbox::Metadata] metadata
    # @return [String] copy_reference
    def get_copy_reference(path)
      resp = request('/files/copy_reference/get', path: path)
      metadata = parse_tagged_response(resp['metadata'])
      return metadata, resp['copy_reference']
    end

    # Save a copy reference to the user's Dropbox.
    #
    # @param [String] copy_reference
    # @param [String] path
    # @return [Dropbox::Metadata] metadata
    def save_copy_reference(copy_reference, path)
      resp = request('/files/copy_reference/save', copy_reference: copy_reference, path: path)
      parse_tagged_response(resp['metadata'])
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

    # Get the contents of a folder that are after a cursor.
    #
    # @param [String] cursor
    # @return [Array<Dropbox::Metadata>]
    def continue_list_folder(cursor)
      resp = request('/files/list_folder/continue', cursor: cursor)
      resp['entries'].map { |e| parse_tagged_response(e) }
    end

    # Get a cursor for a folder's current state.
    #
    # @param [String] path
    # @return [String] cursor
    def get_latest_list_folder_cursor(path)
      resp = request('/files/list_folder/get_latest_cursor', path: path)
      resp['cursor']
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

    # Permanently delete the file or folder at a given path.
    #
    # @param [String] path
    # @return [void]
    def permanently_delete(path)
      request('/files/permanently_delete', path: path)
      nil
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

    # Save a specified URL into a file in user's Dropbox.
    #
    # @param [String] path
    # @param [String] url
    # @return [String] the job id, if the processing is asynchronous.
    # @return [Dropbox::FileMetadata] if the processing is synchronous.
    def save_url(path, url)
      resp = request('/files/save_url', path: path, url: url)
      parse_tagged_response(resp)
    end

    # Check the status of a save_url job.
    #
    # @param [String] async_job_id
    # @return [nil] if the job is still in progress.
    # @return [Dropbox::FileMetadata] if the job is complete.
    # @return [String] an error message, if the job failed.
    def check_save_url_job_status(async_job_id)
      resp = request('/files/save_url/check_job_status', async_job_id: async_job_id)
      parse_tagged_response(resp)
    end

    # Search for files and folders.
    #
    # @param [String] path
    # @param [String] query
    # @param [Integer] start
    # @param [Integer] max_results
    # @param [String] mode
    # @return [Array<Dropbox::Metadata>] matches
    def search(path, query, start=0, max_results=100, mode='filename')
      resp = request('/files/search', path: path, query: query, start: start,
        max_results: max_results, mode: mode)
      matches = resp['matches'].map { |m| parse_tagged_response(m['metadata']) }
      return matches
    end

    # Create a new file.
    #
    # @param [String] path
    # @param [String, Enumerable] body
    # @option options [String] :mode
    # @option options [Boolean] :autorename
    # @option options [Boolean] :mute
    # @return [Dropbox::FileMetadata]
    def upload(path, body, options={})
      options[:client_modified] = Time.now.utc.iso8601
      options[:path] = path
      resp = upload_request('/files/upload', body, options.merge(path: path))
      FileMetadata.new(resp)
    end

    # Start an upload session to upload a file using multiple requests.
    #
    # @param [String, Enumerable] body
    # @param [Boolean] close
    # @return [Dropbox::UploadSessionCursor] cursor
    def start_upload_session(body, close=false)
      resp = upload_request('/files/upload_session/start', body, close: close)
      UploadSessionCursor.new(resp['session_id'], body.length)
    end

    # Append more data to an upload session.
    #
    # @param [Dropbox::UploadSessionCursor] cursor
    # @param [String, Enumerable] body
    # @param [Boolean] close
    # @return [Dropbox::UploadSessionCursor] cursor
    def append_upload_session(cursor, body, close=false)
      args = {cursor: cursor.to_h, close: close}
      resp = upload_request('/files/upload_session/append_v2', body, args)
      cursor.offset += body.length
      cursor
    end

    # Finish an upload session and save the uploaded data to the given file path.
    #
    # @param [Dropbox::UploadSessionCursor] cursor
    # @param [String] path
    # @param [String, Enumerable] body
    # @param [Hash] options
    # @option (see #upload)
    # @return [Dropbox::FileMetadata]
    def finish_upload_session(cursor, path, body, options={})
      options[:client_modified] = Time.now.utc.iso8601
      options[:path] = path
      args = {cursor: cursor.to_h, commit: options}
      resp = upload_request('/files/upload_session/finish', body, args)
      FileMetadata.new(resp)
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

    # Get the space usage information for the current user's account.
    #
    # @return [Dropbox::SpaceUsage]
    def get_space_usage
      resp = request('/users/get_space_usage')
      SpaceUsage.new(resp)
    end

    # List shared folders owned by the current user
    # @param limit [Integer] The maximum number of results to return. Defaults to 1000
    # @return [Array<Dropbox::FileMetadata>] entries
    # @return [String] cursor
    def list_shared_folders(limit = 1000)
      resp = request('/sharing/list_folders', limit: limit)
      entries = resp['entries'].map { |entry| FolderMetadata.new(entry) }
      [entries, resp['cursor']]
    end

    # Continue the list of shared folders
    # @param cursor [String]
    # @return [Array<Dropbox::FileMetadata>] entries
    # @return [String] cursor
    def continue_list_shared_folders(cursor)
      resp = request('/sharing/list_folders/continue', cursor: cursor)
      entries = resp['entries'].map { |entry| FolderMetadata.new(entry) }
      [entries, resp['cursor']]
    end

    # Make a folder shared
    # @param path [String] The path to the folder to be made shared
    # @param member_policy [String] Can be 'anyone' or 'team'. Defaults to 'anyone'.
    # @param acl_update_policy [String] Can be 'owner' or 'editors'. Defaults to 'owner'.
    # @param shared_link_policy [String] Can be 'anyone' or 'editors'. Defaults to 'anyone'.
    # @param force_async [Boolean] Defaults to false.
    # @return [String] the job id, if the processing is asynchronous.
    # @return [Dropbox::SharedFolderMetadata] if the processing is synchronous
    def share_folder(path, member_policy: 'anyone', acl_update_policy: 'owner', shared_link_policy: 'anyone', force_async: false)
      resp = request('/sharing/share_folder', path: path, member_policy: member_policy, acl_update_policy: acl_update_policy, shared_link_policy: shared_link_policy, force_async: force_async)
      parse_tagged_response(resp)
    end

    # Update the sharing policies for a shared folder.
    # @params shared_folder_id [String] The shared_id of the folder
    # @params member_policy [String]. Can be nil, 'anyone' or 'team'. Defaults to nil
    # @params acl_update_policy [String]. Can be nil, 'owner' or 'editors'. Defaults to nil.
    # @params shared_link_policy [String]. Can be nil, 'anyone' or 'members'. Defaults to nil.
    # @return [Dropbox::SharedFolderMetadata]
    def update_folder_policy(shared_folder_id, member_policy: nil, acl_update_policy: nil, shared_link_policy: nil)
      data = {shared_folder_id: shared_folder_id}
      data[:member_policy] = member_policy if member_policy
      data[:acl_update_policy] = acl_update_policy if acl_update_policy
      data[:shared_link_policy] = shared_link_policy if shared_link_policy
      resp = request('/sharing/update_folder_policy', data)
      SharedFolderMetadata.new(resp)
    end

    # Add a member to a shared folder
    # @param shared_folder_id [String] The shared_id of the folder
    # @param members [Array<String>] An array of emails as Strings.
    # @param quiet [Boolean] defaults to false
    # @param custom_message [String] A custom message to be sent to all of the members. Defaults to nil.
    # @param access_level [String] The access level given to all members. Can be 'editor', 'viewer' or 'viewer_no_comment'. Defaults to 'editor'.
    # @return [void]
    def add_folder_member(shared_folder_id, members, quiet: false, custom_message: nil, access_level: 'editor')
      params = {shared_folder_id: shared_folder_id, quiet: quiet}
      params[:members] = members.map do |member|
        {
          'member' => {
            '.tag' => 'email',
            'email' => member
          },
          'access_level' => {
            '.tag' => access_level
          }
        }
      end
      params[:custom_message] = custom_message if custom_message

      request('/sharing/add_folder_member', params)
      nil
    end

    # Mount a folder (accept a share request)
    # @param shared_folder_id [String]
    # @return [Dropbox::SharedFolderMetadata]
    def mount_folder(shared_folder_id)
      resp = request('/sharing/mount_folder', shared_folder_id: shared_folder_id)
      SharedFolderMetadata.new(resp)
    end

    # List members of a shared folder
    # @param shared_folder_id [String]
    # @return [Array<Dropbox::UserMembershipInfo>]
    def list_folder_members(shared_folder_id)
      resp = request('/sharing/list_folder_members', shared_folder_id: shared_folder_id)
      resp['users'].map {|user| UserMembershipInfo.new(user)}
    end

    # Relinquish membership of a shared folder you are a member of
    # @param shared_folder_id [String]
    # @param leave_a_copy [String] default false
    # @return [String] 'complete' if the processing is complete
    # @return [String] the job id, if the processing is asynchronous.
    def relinquish_folder_membership(shared_folder_id, leave_a_copy: false)
      resp = request('/sharing/relinquish_folder_membership', shared_folder_id: shared_folder_id, leave_a_copy: leave_a_copy)
      parse_tagged_response(resp)
    end

    # Transfer ownership of a shared folder to another member of the folder
    # @param shared_folder_id [String]
    # @param to_dropbox_id [String]
    # @return [void]
    def transfer_folder(shared_folder_id, to_dropbox_id)
      request('/sharing/transfer_folder', shared_folder_id: shared_folder_id, to_dropbox_id: to_dropbox_id)
      nil
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
        when 'complete'
          if resp['time_invited']
            SharedFolderMetadata.new(resp)
          elsif resp['client_modified']
            FileMetadata.new(resp)
          else
            'complete'
          end
        when 'async_job_id'
          resp['async_job_id']
        when 'in_progress'
          nil
        when 'failed'
          resp['failed']['.tag']
        else
          raise ClientError.unknown_response_type(resp['.tag'])
        end
      end

      def request(action, data=nil)
        url = API + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers(content_type: ('application/json' if data))
          .post(url, json: data)

        raise ApiError.new(resp) if resp.code != 200
        resp.parse
      end

      def content_request(action, args={})
        url = CONTENT_API + action
        resp = HTTP.auth('Bearer ' + @access_token)
          .headers('Dropbox-API-Arg' => args.to_json).get(url)

        raise ApiError.new(resp) if resp.code != 200
        file = JSON.parse(resp.headers['Dropbox-API-Result'])
        return file, resp.body
      end

      def upload_request(action, body, args={})
        resp = HTTP.auth('Bearer ' + @access_token).headers({
          'Content-Type' => 'application/octet-stream',
          'Dropbox-API-Arg' => args.to_json,
          'Transfer-Encoding' => ('chunked' unless body.is_a?(String))
        }).post(CONTENT_API + action, body: body)

        raise ApiError.new(resp) if resp.code != 200
        JSON.parse(resp.to_s) unless resp.to_s == 'null'
      end
  end
end
