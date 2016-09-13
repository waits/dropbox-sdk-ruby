require 'test_helper'
require 'time'

class DropboxMetadataTest < Minitest::Test
  def test_folder_initialize
    folder = Dropbox::FolderMetadata.new('id' => 'id:123', 'name' => 'child',
      'path_lower' => '/parent/middle/child', 'path_display' => '/parent/middle/child', 'shared_folder_id' => '1234', 'parent_shared_folder_id' => 'abcd')
    assert_equal 'id:123', folder.id
    assert_equal 'child', folder.name
    assert_equal '/parent/middle/child', folder.path_lower
    assert_equal '/parent/middle/child', folder.path_display
    assert_equal '1234', folder.shared_folder_id
    assert_equal 'abcd', folder.parent_shared_folder_id
  end

  def test_file_initialize
    file = Dropbox::FileMetadata.new('id' => 'id:123', 'name' => 'file',
      'path_lower' => '/folder/file', 'path_display' => '/folder/file',
      'size' => 11, 'server_modified' => '2007-07-07T00:00:00Z')
    assert_equal 'id:123', file.id
    assert_equal 'file', file.name
    assert_equal '/folder/file', file.path_lower
    assert_equal '/folder/file', file.path_display
    assert_equal 11, file.size
  end

  def test_folder_equality
    a = Dropbox::FolderMetadata.new('id' => 'id:123', 'name' => 'child',
      'path_lower' => '/parent/middle/child', 'path_display' => '/parent/middle/child')
    b = Dropbox::FolderMetadata.new('id' => 'id:123', 'name' => 'child',
      'path_lower' => '/parent/middle/child', 'path_display' => '/parent/middle/child')

    assert_equal a, b
  end

  def test_file_equality
    a = Dropbox::FileMetadata.new('id' => 'id:123', 'name' => 'file',
      'path_lower' => '/folder/file', 'path_display' => '/folder/file',
      'size' => 11, 'server_modified' => '2007-07-07T00:00:00Z')
    b = Dropbox::FileMetadata.new('id' => 'id:123', 'name' => 'file',
      'path_lower' => '/folder/file', 'path_display' => '/folder/file',
      'size' => 11, 'server_modified' => '2007-07-07T00:00:00Z')

    assert_equal a, b
  end
end
