require 'minitest/autorun'
require 'dropbox'

class DropboxUsersTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new(ENV['DROPBOX_SDK_ACCESS_TOKEN'])
  end

  def test_get_account
    id = @client.get_current_account.account_id
    account = @client.get_account(id)

    assert account.is_a?(Dropbox::BasicAccount)
    assert_equal id, account.account_id
  end

  def test_get_account_error
    assert_raises(Dropbox::APIError) do
      @client.get_account('invalid_id')
    end
  end

  def test_get_account_batch
    id = @client.get_current_account.account_id
    accounts = @client.get_account_batch([id])

    assert_equal 1, accounts.length
    assert accounts[0].is_a?(Dropbox::BasicAccount)
    assert_equal id, accounts[0].account_id
  end

  def test_get_account_batch_error
    assert_raises(Dropbox::APIError) do
      @client.get_account_batch(['invalid_id'])
    end
  end

  def test_get_current_account
    account = @client.get_current_account

    assert account.is_a?(Dropbox::FullAccount)
    assert_match /^dbid:[a-z0-9_-]+$/i, account.account_id
    assert_equal 'Dylan Waits', account.display_name
    assert_equal true, account.email_verified
    assert_equal false, account.disabled
  end

  def test_get_space_usage
    usage = @client.get_space_usage

    assert usage.used.is_a?(Integer)
    assert_equal 'individual', usage.allocation
    assert usage.allocated.is_a?(Integer)
  end

end
