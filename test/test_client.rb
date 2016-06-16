require 'minitest/autorun'
require 'dropbox'

class DropboxClientTest < Minitest::Test
  def test_client_initialize
    dbx = Dropbox::Client.new('12345678' * 8)

    assert dbx.is_a?(Dropbox::Client), 'Dropbox::Client did not initialize'
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
      dbx.revoke_token
    end
  end
end
