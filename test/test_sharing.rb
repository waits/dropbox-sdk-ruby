require 'test_helper'

class DropboxSharingTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new('super-fake-access-token-1234567890000000000000000000000000000000')
  end

  def test_share_folder
    stub_request(:post, url('sharing/share_folder')).to_return(stub('share_folder'))
    share = @client.share_folder('/test/share_me')
    assert_equal '/test/share_me', share.path_lower
  end

  def test_add_folder_member
    stub_request(:post, url('sharing/add_folder_member')).to_return(stub('null'))
    result = @client.add_folder_member(shared_folder_id: '123123', members: %w(one@example.com two@example.com))
    assert_nil result
  end

  def test_mount_folder
    stub_request(:post, url('sharing/mount_folder')).to_return(stub('share_folder'))
    share = @client.mount_folder('123123')
    assert_equal '/test/share_me', share.path_lower
  end

  def test_list_folder_members
    stub_request(:post, url('sharing/list_folder_members')).to_return(stub('list_folder_members'))
    list = @client.list_folder_members('123123')
    assert_equal 3, list.length
    assert_equal 'dbid:user1', list.first.account_id
  end

  def test_transfer_folder
    stub_request(:post, url('sharing/transfer_folder')).to_return(stub('null'))
    result = @client.transfer_folder('123123123', '123123aaa')
    assert_nil result
  end

  def test_relinquish_membership
    stub_request(:post, url('sharing/relinquish_folder_membership')).to_return(stub('complete'))
    result = @client.relinquish_folder_membership('123123')
    assert_equal 'complete', result
  end
end
