require 'time'

module Dropbox
  # Abstract class inherited by the other metadata classes.
  class Metadata
    attr_reader :name, :path_lower, :path_display

    def initialize(attrs={})
      @name = attrs['name']
      @path_lower = attrs['path_lower']
      @path_display = attrs['path_display']
    end
  end

  # Contains the metadata (but not contents) of a file.
  class FileMetadata < Metadata
    attr_reader :id, :client_modified, :server_modified, :rev, :size

    def initialize(attrs={})
      @id = attrs.delete('id')
      if cm = attrs.delete('client_modified')
        @client_modified = Time.parse(cm)
      end
      @server_modified = Time.parse(attrs.delete('server_modified'))
      @rev = attrs.delete('rev')
      @size = attrs.delete('size')
      super(attrs)
    end

    def ==(cmp)
      cmp.is_a?(self.class) && self.id == cmp.id
    end
  end

  # Contains the metadata (but not contents) of a folder.
  class FolderMetadata < Metadata
    attr_reader :id

    def initialize(attrs={})
      @id = attrs.delete('id')
      super(attrs)
    end

    def ==(cmp)
      cmp.is_a?(self.class) && self.id == cmp.id
    end
  end

  # Contains the metadata of a deleted file.
  class DeletedMetadata < Metadata
  end
end
