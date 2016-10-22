require 'test_helper'

class DropboxSharingTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new('super-fake-access-token-1234567890000000000000000000000000000000')
  end

  def test_create_shared_link_with_setting_for_file
    stub_request(:post, url('sharing/create_shared_link_with_settings')).to_return(stub('create_shared_file_link_with_settings'))
    file = @client.create_shared_link_with_settings('/Homework/Prime_Numbers.txt')

    assert file.is_a?(Dropbox::FileLinkMetadata)
    assert_equal 'https://www.dropbox.com/s/2sn712vy1ovegw8/Prime_Numbers.txt?dl=0', file.url
    assert_match /^id:[a-z0-9_-]+$/i, file.id
    assert_equal 'Prime_Numbers.txt', file.name
    assert file.server_modified.is_a?(Time)
    assert_match /^[a-z0-9_-]+$/i, file.rev
    assert_equal 7212, file.size
    assert file.link_permissions.is_a?(Dropbox::LinkPermissions)
    assert file.team_member_info.is_a?(Dropbox::TeamMemberInfo)
  end

  def test_create_shared_link_with_setting_for_folder
    stub_request(:post, url('sharing/create_shared_link_with_settings')).to_return(stub('create_shared_folder_link_with_settings'))
    folder = @client.create_shared_link_with_settings('/Homework/math')

    assert folder.is_a?(Dropbox::FolderLinkMetadata)
    assert_equal 'https://www.dropbox.com/sh/s6fvw6ol7rmqo1x/AAAgWRSbjmYDvPpDB30Sykjfa?dl=0', folder.url
    assert_match /^id:[a-z0-9_-]+$/i, folder.id
    assert_equal 'Math', folder.name
    assert folder.link_permissions.is_a?(Dropbox::LinkPermissions)
    assert folder.team_member_info.is_a?(Dropbox::TeamMemberInfo)
  end
end

