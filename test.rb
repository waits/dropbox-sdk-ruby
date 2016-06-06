require 'minitest/autorun'
require File.expand_path '../lib/dropbox', __FILE__

class DropboxTest < Minitest::Test
  def test_class
    assert Dropbox::Client.is_a?(Class), 'Dropbox::Client is not a Class'
  end

  def test_initialize
    dbx = Dropbox::Client.new('1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-')
    assert dbx.is_a?(Dropbox::Client)
  end

  def test_initialize_error
    assert_raises(Dropbox::ClientError) do
      dbx = Dropbox::Client.new('')
    end

    assert_raises(Dropbox::ClientError) do
      dbx = Dropbox::Client.new(nil)
    end
  end
end
