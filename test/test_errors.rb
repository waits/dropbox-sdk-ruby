require 'test_helper'
require 'http'

class DropboxErrorTest < Minitest::Test
  def test_client_error
    err = Dropbox::ClientError.invalid_access_token
    assert_equal "Invalid access token", err.to_s

    err = Dropbox::ClientError.unknown_response_type('link')
    assert_equal "Unknown response type 'link'", err.to_s
  end

  def test_api_error
    resp = HTTP::Response.new(status: 404, version: '1.1',
      headers: {'Content-Type' => 'application/json'},
      body: '{"error_summary": "Resource not found"}')
    err = Dropbox::ApiError.new(resp)
    assert_equal 'Resource not found', err.to_s

    resp = HTTP::Response.new(status: 500, version: '1.1',
      headers: {'Content-Type' => 'text/html'},
      body: '<html><body>Server error</body></html>')
    err = Dropbox::ApiError.new(resp)
    assert_equal '<html><body>Server error</body></html>', err.to_s
  end
end
