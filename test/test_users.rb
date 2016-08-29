require 'test_helper'

class DropboxUsersTest < Minitest::Test
  def setup
    @client = Dropbox::Client.new(ENV['DROPBOX_SDK_ACCESS_TOKEN'])
  end

  def test_get_account
    stub_request(:post, url('users/get_account')).to_return(stub('get_account'))
    id = 'dbid:AAH4f99T0taONIb-OurWxbNQ6ywGRopQngc'
    account = @client.get_account(id)

    assert account.is_a?(Dropbox::BasicAccount)
    assert_equal id, account.account_id
  end

  def test_get_account_error
    stub_request(:post, url('users/get_account')).to_return(error('no_account'))
    assert_raises(Dropbox::ApiError) do
      @client.get_account('invalid_id')
    end
  end

  def test_get_account_batch
    stub_request(:post, url('users/get_account_batch')).to_return(stub('get_account_batch'))
    id = 'dbid:AAH4f99T0taONIb-OurWxbNQ6ywGRopQngc'
    accounts = @client.get_account_batch([id])

    assert_equal 1, accounts.length
    assert accounts[0].is_a?(Dropbox::BasicAccount)
    assert_equal id, accounts[0].account_id
  end

  def test_get_account_batch_error
    stub_request(:post, url('users/get_account_batch')).to_return(error('no_account'))
    assert_raises(Dropbox::ApiError) do
      @client.get_account_batch(['invalid_id'])
    end
  end

  def test_get_current_account
    stub_request(:post, url('users/get_current_account')).to_return(stub('get_current_account'))
    account = @client.get_current_account

    assert account.is_a?(Dropbox::FullAccount)
    assert_match /^dbid:[a-z0-9_-]+$/i, account.account_id
    assert_equal 'Franz Ferdinand (Personal)', account.display_name
    assert_equal false, account.email_verified
    assert_equal false, account.disabled
  end

  def test_get_space_usage
    stub_request(:post, url('users/get_space_usage')).to_return(stub('get_space_usage'))
    usage = @client.get_space_usage

    assert usage.used.is_a?(Integer)
    assert_equal 'individual', usage.allocation
    assert usage.allocated.is_a?(Integer)
  end

end
