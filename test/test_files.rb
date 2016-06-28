require 'minitest/autorun'
require 'dropbox'
require 'time'

class DropboxFilesTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new(ENV['DROPBOX_SDK_ACCESS_TOKEN'])
  end

  def test_copy
    path = '/copied_folder'
    folder = @client.copy('/empty_folder', path)

    assert_equal 'copied_folder', folder.name

    @client.delete(path)
  end

  def test_copy_error
    assert_raises(Dropbox::APIError) do
      @client.copy('/empty_folder', '/empty_folder')
    end
  end

  def test_create_folder
    path = '/temp_dir'
    folder = @client.create_folder(path)

    assert folder.is_a?(Dropbox::FolderMetadata)
    assert_match /^id:[a-z0-9_-]+$/i, folder.id
    assert_equal 'temp_dir', folder.name
    assert_equal path, folder.path_lower

    @client.delete(path)
  end

  def test_create_folder_error
    assert_raises(Dropbox::APIError) do
      @client.create_folder('malformed')
    end
  end

  def test_delete_folder
    path = '/folder_to_delete'
    @client.create_folder(path)
    folder = @client.delete(path)

    assert folder.is_a?(Dropbox::FolderMetadata)
    assert_equal path[1..-1], folder.name
  end

  def test_delete_folder_error
    assert_raises(Dropbox::APIError) do
      @client.delete('/doesnotexist')
    end
  end

  def test_download
    file, content = @client.download('/file.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal "Example file contents\n", content.to_s
  end

  def test_download_error
    assert_raises(Dropbox::APIError) do
      @client.download('/does_not_exist')
    end
  end

# TODO: Getting 500 errors from the API. Mention it to Dropbox.
#
#   def test_get_save_copy_reference
#     meta, ref = @client.get_copy_reference('/file.txt')
#
#     assert meta.is_a?(Dropbox::FileMetadata)
#     assert ref.is_a?(String)
#     assert_match /^[a-z0-9]+$/i, ref
#
#     saved_meta = @client.save_copy_reference('/copied_file.txt')
#
#     assert meta.is_a?(Dropbox::FileMetadata)
#     assert_equal 'copied_file.txt', file.name
#     assert_equal 22, file.size
#   end

  def test_get_copy_reference_error
    assert_raises(Dropbox::APIError) do
      @client.get_copy_reference('/not_found')
    end
  end

  def test_get_metadata
    file = @client.get_metadata('/file.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_match /^id:[a-z0-9_-]+$/i, file.id
    assert_equal 'file.txt', file.name
    assert file.server_modified.is_a?(Time)
    assert_match /^[a-z0-9_-]+$/i, file.rev
    assert_equal 22, file.size
  end

  def test_get_metadata_error
    assert_raises(Dropbox::APIError) do
      @client.get_metadata('/does_not_exist')
    end
  end

  def test_get_preview
    file, content = @client.get_preview('/fox.docx')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_match "%PDF-1.4", content.to_s
  end

  def test_get_preview_error
    assert_raises(Dropbox::APIError) do
      @client.get_preview('/file.txt')
    end
  end

  def test_get_temporary_link
    file, link = @client.get_temporary_link('/file.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal 'file.txt', file.name
    assert_equal 22, file.size
    assert_match 'https://dl.dropboxusercontent.com/apitl/1', link
  end

  def test_get_temporary_link_error
    assert_raises(Dropbox::APIError) do
      @client.get_temporary_link('/folder_to_search')
    end
  end

  def test_get_thumbnail
    file, content = @client.get_thumbnail('/image.png', 'png', 'w32h32')

    assert file.is_a?(Dropbox::FileMetadata)
  end

  def test_get_thumbnail_error
    assert_raises(Dropbox::APIError) do
      @client.get_thumbnail('/file.txt')
    end
  end

  def test_list_folder
    entries = @client.list_folder('/folder_to_list')

    assert entries[0].is_a?(Dropbox::FolderMetadata)
    assert_equal 'subfolder', entries[0].name
    assert entries[1].is_a?(Dropbox::FileMetadata)
    assert_equal 'file.txt', entries[1].name
    assert_equal 4, entries[1].size
  end

  def test_list_folder_empty
    entries = @client.list_folder('/empty_folder')

    assert_equal 0, entries.length
  end

  def test_list_folder_error
    assert_raises(Dropbox::APIError) do
      @client.list_folder('/file.txt')
    end
  end

  def test_list_revisions
    entries, is_deleted = @client.list_revisions('/file.txt')

    assert_equal 1, entries.length
    assert_equal false, is_deleted
  end

  def test_list_revisions_error
    assert_raises(Dropbox::APIError) do
      @client.list_revisions('/folder_to_search')
    end
  end

  def test_move
    from, to = '/empty_folder', '/moved_folder'
    folder = @client.move(from, to)

    assert_equal 'moved_folder', folder.name

    @client.move(to, from)
  end

  def test_move_error
    assert_raises(Dropbox::APIError) do
      @client.move('/does_not_exist', '/does_not_exist')
    end
  end

  def test_restore
    file = @client.restore('/file.txt', '14449c1893e')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal 'file.txt', file.name
  end

  def test_restore_error
    assert_raises(Dropbox::APIError) do
      @client.restore('/file.txt', 'xyz')
    end
  end

#   def test_save_url
#     job_id = @client.save_url('/saved_file.txt', 'https://www.dropbox.com/robots.txt')
#
#     assert job_id.is_a?(String)
#     assert_match /^[a-z0-9_-]{22}$/i, job_id
#   end

  def test_save_url_error
    assert_raises(Dropbox::APIError) do
      @client.save_url('/saved_file.txt', 'ht:/invalid_url')
    end
  end

  def test_save_copy_reference_error
    assert_raises(Dropbox::APIError) do
      @client.save_copy_reference('invalid', '/saved_copy_reference.txt')
    end
  end

  def test_search
    matches = @client.search('', 'search')
    assert_equal 2, matches.length
    assert matches[0].is_a?(Dropbox::FolderMetadata)
    assert matches[1].is_a?(Dropbox::FileMetadata)

    matches = @client.search('/folder_to_search', 'sub')
    assert_equal 2, matches.length

    matches = @client.search('/folder_to_search', 'sub', 0, 1)
    assert_equal 1, matches.length
  end

  def test_search_error
    assert_raises(Dropbox::APIError) do
      @client.search('subfolder', '/')
    end
  end

  def test_upload_string
    now = Time.now.utc
    file = @client.upload('/uploaded_string.txt', 'dropbox', mode: 'overwrite',
      autorename: false)

    assert_instance_of(Dropbox::FileMetadata, file)
    assert_equal(7, file.size)
    assert_in_delta(now.to_i, file.client_modified.to_i, 5, "Expected #{file.client_modified} to be near #{now}")

    @client.delete('/uploaded_string.txt')
  end

  def test_upload_file
    File.open('LICENSE') do |f|
      now = Time.now.utc
      meta = @client.upload('/license.txt', f, mode: 'overwrite')

      assert_instance_of(Dropbox::FileMetadata, meta)
      assert_equal(1078, meta.size)
      assert_in_delta(now.to_i, meta.client_modified.to_i, 5, "Expected #{meta.client_modified} to be near #{now}")
    end

    @client.delete('/license.txt')
  end

  def test_upload_conflict
    assert_raises(Dropbox::APIError) do
      @client.upload('/uploaded_file.txt', 'dropbocks', mode: 'add', autorename: false)
    end
  end
end
