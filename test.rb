require 'minitest/autorun'
require File.expand_path '../lib/dropbox', __FILE__

class DropboxTest < Minitest::Test
  def test_class
    assert Dropbox.is_a?(Class)
  end
end
