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
    assert_equal nil, result
  end

  def test_mount_folder
    stub_request(:post, url('sharing/mount_folder')).to_return(stub('share_folder'))
    share = @client.mount_folder('123123')
    assert_equal '/test/share_me', share.path_lower
  end
end
