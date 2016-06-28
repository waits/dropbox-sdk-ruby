module Dropbox
  # UploadSessionCursor holds information about an in-progress upload session.
  #
  # @attr [String] session_id A unique identifier for the session.
  # @attr [Integer] offset The size of the data uploaded so far.
  class UploadSessionCursor
    attr_reader :session_id
    attr_accessor :offset

    # @param [String] session_id
    # @param [Integer] offset
    def initialize(session_id, offset)
      @session_id = session_id
      @offset = offset
    end

    # @return [Hash]
    def to_h
      {session_id: session_id, offset: offset}
    end
  end
end
