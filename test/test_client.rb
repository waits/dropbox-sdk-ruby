require 'minitest/autorun'
require 'dropbox'

class DropboxClientTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new(ENV['DROPBOX_SDK_ACCESS_TOKEN'])
    @nonce = Time.now.to_i.to_s
  end

  def test_client_initialize
    assert @client.is_a?(Dropbox::Client), 'Dropbox::Client did not initialize'
  end

  def test_client_initialize_error
    assert_raises(Dropbox::ClientError) do
      Dropbox::Client.new('')
    end

    assert_raises(Dropbox::ClientError) do
      Dropbox::Client.new(nil)
    end
  end

  def test_invalid_access_token
    dbx = Dropbox::Client.new('12345678' * 8)

    assert_raises(Dropbox::APIError) do
      dbx.list_folder('/somedir')
    end
  end

  def test_copy
    path = '/copied_folder'
    folder = @client.copy('/folder_to_copy', path)

    assert_equal 'copied_folder', folder.name

    @client.delete(path)
  end

  def test_copy_error
    assert_raises(Dropbox::APIError) do
      @client.copy('/folder_to_copy', '/folder_to_copy')
    end
  end

  def test_create_folder
    path = '/temp_dir'
    folder = @client.create_folder(path)

    assert folder.is_a?(Dropbox::FolderMetadata)
    assert_equal path, folder.path

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

  def test_list_folder
    entries = @client.list_folder('/folder_to_list')

    assert entries[0].is_a?(Dropbox::FolderMetadata)
    assert_equal 'subfolder', entries[0].name
    assert entries[1].is_a?(Dropbox::FileMetadata)
    assert_equal 'file.txt', entries[1].name
    assert_equal 4, entries[1].size
  end

  def test_list_folder_error
    assert_raises(Dropbox::APIError) do
      @client.list_folder('/doesnotexist')
    end
  end

  def test_move
    from, to = '/folder_to_move', '/moved_folder'
    @client.create_folder(from)
    folder = @client.move(from, to)

    assert_equal 'moved_folder', folder.name

    @client.delete(to)
  end

  def test_move_error
    assert_raises(Dropbox::APIError) do
      @client.move('/does_not_exist', '/does_not_exist')
    end
  end

  def test_search
    matches = @client.search('folder')
    assert_equal 3, matches.length
    assert matches[2].is_a?(Dropbox::FolderMetadata)
    assert_equal 'folder_to_search', matches[2].name

    matches = @client.search('sub', '/folder_to_search')
    assert_equal 2, matches.length

    matches = @client.search('sub', '/folder_to_search', 1)
    assert_equal 1, matches.length
  end

  def test_search_error
    assert_raises(Dropbox::APIError) do
      @client.search('subfolder', '/')
    end
  end
end
