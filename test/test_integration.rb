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
    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal file.name, 'file.txt'
    assert_equal 19, file.size

    metadata, body = @client.download(file.path_lower)
    assert_equal file, metadata
    assert_equal "The file contents.\n", body.to_s

    metadata, link = @client.get_temporary_link(file.path_lower)
    assert metadata.is_a?(Dropbox::FileMetadata)
    assert_match 'https://dl.dropboxusercontent.com/apitl/1', link

    @client.delete(file.path_lower)
    revs, is_deleted = @client.list_revisions(file.path_lower)
    assert revs.length > 0
    assert revs[0].is_a?(Dropbox::FileMetadata)
    assert_equal true, is_deleted

    restored = @client.restore(file.path_lower, file.rev)
    assert_equal file, restored

    job_id = @client.save_url(@box.path_lower + '/robots.txt', 'https://www.dropbox.com/robots.txt')
    status = nil
    while status == nil
      status = @client.check_save_url_job_status(job_id)
    end
    assert status.is_a?(Dropbox::FileMetadata)
    assert_equal 'robots.txt', status.name

    job_id = @client.save_url('/nothing.txt', 'https://www.google.com/404')
    status = nil
    while status == nil
      status = @client.check_save_url_job_status(job_id)
    end
    assert status.is_a?(String)
  end

  def test_folders
    folder = @client.create_folder(@box.path_lower + '/folder')
    assert folder.is_a?(Dropbox::FolderMetadata)

    subfolder = @client.create_folder(folder.path_lower + '/subfolder')
    assert subfolder.is_a?(Dropbox::FolderMetadata)

    copied = @client.copy(folder.path_lower, @box.path_lower + '/copied_folder')
    assert copied.is_a?(Dropbox::FolderMetadata)
    assert_equal @box.path_lower + '/copied_folder', copied.path_lower

    moved = @client.move(folder.path_lower, @box.path_lower + '/moved_folder')
    assert moved.is_a?(Dropbox::FolderMetadata)
    assert_equal @box.path_lower + '/moved_folder', moved.path_lower
    @client.move(moved.path_lower, folder.path_lower)

    entries = @client.list_folder(folder.path_lower)
    assert_equal 1, entries.length
    assert entries[0].is_a?(Dropbox::FolderMetadata)

    matches = @client.search(@box.path_lower, 'nothing')
    assert_equal 0, matches.length

    deleted_folder = @client.delete(folder.path_lower)
    assert_equal folder, deleted_folder
    assert_raises(Dropbox::APIError) { @client.delete(folder.path_lower) }
  end
end
