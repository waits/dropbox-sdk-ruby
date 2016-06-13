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
    attr_reader :size

    def initialize(id, path, size)
      @size = size
      super(id, path)
    end
  end

  class FolderMetadata < Metadata
  end
end
