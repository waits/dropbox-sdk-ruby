require 'minitest/autorun'
require 'dropbox'
require 'time'

class DropboxIntegrationTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new(ENV['DROPBOX_SDK_ACCESS_TOKEN'])
    @box = @client.create_folder('/integration_test_container')
  end

  def teardown
    @client.delete(@box.path_lower)
  end

  def test_files
    file = @client.upload(@box.path_lower + '/file.txt', "The file contents.\n")
    assert_instance_of Dropbox::FileMetadata, file
    assert_equal file.name, 'file.txt'
    assert_equal 19, file.size
    assert_in_delta Time.now.to_i, file.client_modified.to_i, 5

    metadata, body = @client.download(file.path_lower)
    assert_equal file, metadata
    assert_equal "The file contents.\n", body.to_s

    metadata, link = @client.get_temporary_link(file.path_lower)
    assert_instance_of Dropbox::FileMetadata, metadata
    assert_match 'https://dl.dropboxusercontent.com/apitl/1', link

    @client.delete(file.path_lower)
    revs, is_deleted = @client.list_revisions(file.path_lower)
    assert revs.length > 0
    assert_instance_of Dropbox::FileMetadata, revs[0]
    assert_equal true, is_deleted

    restored = @client.restore(file.path_lower, file.rev)
    assert_equal file, restored

    job_id = @client.save_url(@box.path_lower + '/robots.txt', 'https://www.dropbox.com/robots.txt')
    status = nil
    while status == nil
      status = @client.check_save_url_job_status(job_id)
    end
    assert_instance_of Dropbox::FileMetadata, status
    assert_equal 'robots.txt', status.name
  end

  def test_folders
    folder = @client.create_folder(@box.path_lower + '/folder')
    assert_instance_of Dropbox::FolderMetadata, folder

    subfolder = @client.create_folder(folder.path_lower + '/subfolder')
    assert_instance_of Dropbox::FolderMetadata, subfolder

    copied = @client.copy(folder.path_lower, @box.path_lower + '/copied_folder')
    assert_instance_of Dropbox::FolderMetadata, copied
    assert_equal @box.path_lower + '/copied_folder', copied.path_lower

    moved = @client.move(folder.path_lower, @box.path_lower + '/moved_folder')
    assert_instance_of Dropbox::FolderMetadata, moved
    assert_equal @box.path_lower + '/moved_folder', moved.path_lower
    @client.move(moved.path_lower, folder.path_lower)

    entries = @client.list_folder(folder.path_lower)
    assert_equal 1, entries.length
    assert_instance_of Dropbox::FolderMetadata, entries[0]

    matches = @client.search(@box.path_lower, 'nothing')
    assert_equal 0, matches.length

    deleted_folder = @client.delete(folder.path_lower)
    assert_equal folder, deleted_folder
    assert_raises(Dropbox::APIError) { @client.delete(folder.path_lower) }
  end

  def test_upload_session
    cursor = @client.start_upload_session("Upload session part 1\n")
    assert_instance_of Dropbox::UploadSessionCursor, cursor
    assert cursor.session_id.is_a?(String)
    assert_equal 22, cursor.offset

    cursor = @client.append_upload_session(cursor, "Upload session part 2\n", false)
    assert_equal 44, cursor.offset

    cursor = @client.append_upload_session(cursor, "Upload session part 3\n", false)
    assert_equal 66, cursor.offset

    file = @client.finish_upload_session(cursor, "/large_file.txt", "Finished\n")
    assert_instance_of Dropbox::FileMetadata, file
    assert_equal 75, file.size
  end
end
