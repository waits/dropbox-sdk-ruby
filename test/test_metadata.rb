require 'minitest/autorun'
require 'dropbox'

class DropboxMetadataTest < Minitest::Test
  def test_folder_initialize
    folder = Dropbox::FolderMetadata.new('id:123', '/parent/middle/child')
    assert_equal 'child', folder.name
  end

  def test_file_initialize
    file = Dropbox::FileMetadata.new('id:123', '/folder/file', 11)
    assert_equal 'file', file.name
    assert_equal 11, file.size
  end
end
