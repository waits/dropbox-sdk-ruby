require 'minitest/autorun'
require 'dropbox'

class DropboxUploadSessionCursorTest < Minitest::Test
  def test_upload_session_cursor
    cursor = Dropbox::UploadSessionCursor.new('id:123', 10)
    hash = cursor.to_h
    correct = {session_id: 'id:123', offset: 10}

    assert_instance_of Hash, hash
    assert_equal correct, hash
  end
end
