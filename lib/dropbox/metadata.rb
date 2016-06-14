module Dropbox
  class Metadata
    attr_reader :id, :path, :name

    def initialize(id, path)
      @id = id
      @path = path
      @name = path.split('/').last
    end
  end

  class FileMetadata < Metadata
    attr_reader :client_modified, :size

    def initialize(id, path, size, client_modified=nil)
      @size = size
      @client_modified = client_modified
      super(id, path)
    end
  end

  class FolderMetadata < Metadata
  end
end
