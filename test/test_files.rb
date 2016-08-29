require 'test_helper'

class DropboxFilesTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new('super-fake-access-token-1234567890000000000000000000000000000000')
  end

  def test_copy
    stub_request(:post, url('files/copy')).to_return(stub('folder'))
    folder = @client.copy('/Homework/physics', '/Homework/math')

    assert_equal 'math', folder.name
  end

  def test_copy_error
    stub_request(:post, url('files/copy')).to_return(error('cant_move_folder_into_itself'))
    assert_raises(Dropbox::ApiError) do
      @client.copy('/empty_folder', '/empty_folder')
    end
  end

  def test_create_folder
    stub_request(:post, url('files/create_folder')).to_return(stub('folder'))
    path = '/Homework/math'
    folder = @client.create_folder(path)

    assert folder.is_a?(Dropbox::FolderMetadata)
    assert_match /^id:[a-z0-9_-]+$/i, folder.id
    assert_equal 'math', folder.name
    assert_equal path, folder.path_display
  end

  def test_create_folder_error
    stub_request(:post, url('files/create_folder')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.create_folder('/doesnotexist')
    end
  end

  def test_delete_folder
    stub_request(:post, url('files/delete')).to_return(stub('folder'))
    folder = @client.delete('/Homework/math')

    assert folder.is_a?(Dropbox::FolderMetadata)
    assert_equal 'math', folder.name
  end

  def test_delete_folder_error
    stub_request(:post, url('files/delete')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.delete('/doesnotexist')
    end
  end

  def test_download
    stub_request(:get, content_url('files/download')).to_return(stub('file_content'))
    file, content = @client.download('/Prime_Numbers.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal "2 3 5 7 9 11 13 15 17 19 23 29 31\n", content.to_s
  end

  def test_download_error
    stub_request(:get, content_url('files/download')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.download('/does_not_exist')
    end
  end

  def test_get_copy_reference
    stub_request(:post, url('files/copy_reference/get')).to_return(stub('copy_reference'))
    meta, ref = @client.get_copy_reference('/Homework/math/Prime_Numbers.txt')

    assert meta.is_a?(Dropbox::FileMetadata)
    assert ref.is_a?(String)
    assert_match /^[a-z0-9]+$/i, ref
  end

  def test_get_copy_reference_error
    stub_request(:post, url('files/copy_reference/get')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.get_copy_reference('/not_found')
    end
  end

  def test_get_metadata
    stub_request(:post, url('files/get_metadata')).to_return(stub('file'))
    file = @client.get_metadata('/Prime_Numbers.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_match /^id:[a-z0-9_-]+$/i, file.id
    assert_equal 'Prime_Numbers.txt', file.name
    assert file.server_modified.is_a?(Time)
    assert_match /^[a-z0-9_-]+$/i, file.rev
    assert_equal 7212, file.size
  end

  def test_get_metadata_error
    stub_request(:post, url('files/get_metadata')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.get_metadata('/does_not_exist')
    end
  end

  def test_get_preview
    stub_request(:get, content_url('files/get_preview')).to_return(stub('file_content'))
    file, content = @client.get_preview('/word.docx')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal 34, content.to_s.length
  end

  def test_get_preview_error
    stub_request(:get, content_url('files/get_preview')).to_return(error('unsupported_extension'))
    assert_raises(Dropbox::ApiError) do
      @client.get_preview('/file.txt')
    end
  end

  def test_get_temporary_link
    stub_request(:post, url('files/get_temporary_link')).to_return(stub('temporary_link'))
    file, link = @client.get_temporary_link('/Homework/math/Prime_Numbers.txt')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal 'Prime_Numbers.txt', file.name
    assert_equal 7212, file.size
    assert_match 'https://dl.dropboxusercontent.com/apitl/1', link
  end

  def test_get_temporary_link_error
    stub_request(:post, url('files/get_temporary_link')).to_return(error('not_file'))
    assert_raises(Dropbox::ApiError) do
      @client.get_temporary_link('/Homework/math')
    end
  end

  def test_get_thumbnail
    stub_request(:get, content_url('files/get_thumbnail')).to_return(stub('thumbnail'))
    file, content = @client.get_thumbnail('/image.png', 'png', 'w32h32')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_match /PNG/, content
  end

  def test_get_thumbnail_error
    stub_request(:get, content_url('files/get_thumbnail')).to_return(error('unsupported_extension'))
    assert_raises(Dropbox::ApiError) do
      @client.get_thumbnail('/file.txt')
    end
  end

  def test_list_folder
    stub_request(:post, url('files/list_folder')).to_return(stub('folder_contents'))
    entries = @client.list_folder('/Homework/math')

    assert_equal 2, entries.length
    assert entries[0].is_a?(Dropbox::FileMetadata)
    assert_equal 'Prime_Numbers.txt', entries[0].name
    assert_equal 7212, entries[0].size
    assert entries[1].is_a?(Dropbox::FolderMetadata)
    assert_equal 'math', entries[1].name
  end

  def test_list_folder_empty
    stub_request(:post, url('files/list_folder')).to_return(stub('empty_folder_contents'))
    entries = @client.list_folder('/empty_folder')

    assert_equal 0, entries.length
  end

  def test_list_folder_error
    stub_request(:post, url('files/list_folder')).to_return(error('not_folder'))
    assert_raises(Dropbox::ApiError) do
      @client.list_folder('/file.txt')
    end
  end

  def test_get_latest_list_folder_cursor
    stub_request(:post, url('files/list_folder/get_latest_cursor')).to_return(stub('cursor'))
    cursor = @client.get_latest_list_folder_cursor('/folder_to_list')
    assert_instance_of String, cursor
    assert_match /^[a-z0-9_-]+$/i, cursor
  end

  def test_continue_list_folder_error
    stub_request(:post, url('files/list_folder/continue')).to_return(error('malformed_path'))
    assert_raises(Dropbox::ApiError) do
      @client.continue_list_folder(nil)
    end
  end

  def test_list_revisions
    stub_request(:post, url('files/list_revisions')).to_return(stub('file_revisions'))
    entries, is_deleted = @client.list_revisions('/Homework/math/Prime_Numbers.txt')

    assert_equal 1, entries.length
    assert_equal false, is_deleted
  end

  def test_list_revisions_error
    stub_request(:post, url('files/list_revisions')).to_return(error('not_file'))
    assert_raises(Dropbox::ApiError) do
      @client.list_revisions('/folder_to_search')
    end
  end

  def test_move
    stub_request(:post, url('files/move')).to_return(stub('folder'))
    from, to = '/Homework/physics', '/Homework/math'
    folder = @client.move(from, to)

    assert_equal 'math', folder.name
  end

  def test_move_error
    stub_request(:post, url('files/move')).to_return(error('not_found'))
    assert_raises(Dropbox::ApiError) do
      @client.move('/does_not_exist', '/does_not_exist')
    end
  end

  def test_restore
    stub_request(:post, url('files/restore')).to_return(stub('file'))
    file = @client.restore('/Homework/math/Prime_Numbers.txt', 'a1c10ce0dd78')

    assert file.is_a?(Dropbox::FileMetadata)
    assert_equal 'Prime_Numbers.txt', file.name
  end

  def test_restore_error
    stub_request(:post, url('files/restore')).to_return(error('invalid_revision'))
    assert_raises(Dropbox::ApiError) do
      @client.restore('/file.txt', 'xyz')
    end
  end

  def test_save_url
    stub_request(:post, url('files/save_url')).to_return(stub('job_id'))
    job_id = @client.save_url('/saved_file.txt', 'https://www.dropbox.com/robots.txt')

    assert job_id.is_a?(String)
    assert_match /^[a-z0-9_-]{22}$/i, job_id
  end

  def test_save_url_error
    stub_request(:post, url('files/save_url')).to_return(error('invalid_url'))
    assert_raises(Dropbox::ApiError) do
      @client.save_url('/saved_file.txt', 'ht:/invalid_url')
    end
  end

  def test_save_copy_reference_error
    stub_request(:post, url('files/copy_reference/save')).to_return(error('invalid_copy_reference'))
    assert_raises(Dropbox::ApiError) do
      @client.save_copy_reference('invalid', '/saved_copy_reference.txt')
    end
  end

  def test_search
    stub_request(:post, url('files/search')).to_return(stub('search_results'))
    matches = @client.search('', 'search')

    assert_equal 1, matches.length
    assert matches[0].is_a?(Dropbox::FileMetadata)
  end

  def test_search_error
    stub_request(:post, url('files/search')).to_return(error('malformed_path'))
    assert_raises(Dropbox::ApiError) do
      @client.search('subfolder', '/')
    end
  end

  def test_upload_string
    stub_request(:post, content_url('files/upload')).to_return(stub('file'))

    now = Time.now.utc
    file = @client.upload('/uploaded_string.txt', 'dropbox', mode: 'overwrite',
      autorename: false)

    assert_instance_of(Dropbox::FileMetadata, file)
    assert_equal(7212, file.size)
    assert_equal(Time.parse('2015-05-12T15:50:38Z'), file.client_modified)
  end

  def test_upload_file
    stub_request(:post, content_url('files/upload')).to_return(stub('file'))

    File.open('LICENSE') do |f|
      now = Time.now.utc
      meta = @client.upload('/license.txt', f, mode: 'overwrite')

      assert_instance_of(Dropbox::FileMetadata, meta)
      assert_equal(7212, meta.size)
      assert_equal(Time.parse('2015-05-12T15:50:38Z'), meta.client_modified)
    end
  end

  def test_upload_conflict
    stub_request(:post, content_url('files/upload')).to_return(error('conflict'))
    assert_raises(Dropbox::ApiError) do
      @client.upload('/uploaded_file.txt', 'dropbocks', mode: 'add', autorename: false)
    end
  end
end
