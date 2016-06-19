require 'minitest/autorun'
require 'dropbox'

class DropboxAccountTest < Minitest::Test
  def test_basic_account_initialize
    account = Dropbox::BasicAccount.new({
      'account_id' => 'id:123',
      'name' => {'display_name' => 'John Smith'},
      'email' => 'email@example.com',
      'email_verified' => true,
      'disabled' => false,
      'profile_photo_url' => 'http://example.com'
    })

    assert_equal 'id:123', account.account_id
    assert_equal 'John Smith', account.display_name
    assert_equal true, account.email_verified
    assert_equal false, account.disabled
  end

  def test_full_account_initialize
    account = Dropbox::FullAccount.new({
      'account_id' => 'id:123',
      'name' => {'display_name' => 'John Smith'},
      'email' => 'email@example.com',
      'email_verified' => true,
      'is_paired' => true,
      'disabled' => false,
      'profile_photo_url' => 'http://example.com'
    })

    assert_equal 'id:123', account.account_id
    assert_equal 'John Smith', account.display_name
    assert_equal true, account.email_verified
    assert_equal false, account.disabled
    assert_equal true, account.is_paired
  end

  def test_space_usage_initialize
    usage = Dropbox::SpaceUsage.new({
      'used' => 1,
      'allocation' => {'.tag' => 'team', 'allocated' => 2}
    })

    assert_equal 1, usage.used
    assert_equal 'team', usage.allocation
    assert_equal 2, usage.allocated
  end
end
