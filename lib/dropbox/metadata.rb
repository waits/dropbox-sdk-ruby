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
    attr_reader :id, :client_modified, :server_modified, :rev, :size, :parent_shared_folder_id

    def initialize(attrs={})
      @id = attrs.delete('id')
      if cm = attrs.delete('client_modified')
        @client_modified = Time.parse(cm)
      end
      @server_modified = Time.parse(attrs.delete('server_modified'))
      @rev = attrs.delete('rev')
      @size = attrs.delete('size')
      @parent_shared_folder_id = attrs.delete('parent_shared_folder_id')
      super(attrs)
    end

    def ==(cmp)
      cmp.is_a?(self.class) && self.id == cmp.id
    end
  end

  # Contains the metadata (but not contents) of a folder.
  class FolderMetadata < Metadata
    attr_reader :id, :shared_folder_id, :parent_shared_folder_id

    def initialize(attrs={})
      @id = attrs.delete('id')
      @shared_folder_id = attrs.delete('shared_folder_id')
      @parent_shared_folder_id = attrs.delete('parent_shared_folder_id')
      super(attrs)
    end

    def ==(cmp)
      cmp.is_a?(self.class) && self.id == cmp.id
    end
  end

  # Contains the metadata of a deleted file.
  class DeletedMetadata < Metadata
  end

  class SharedFolderMetadata < Metadata
    attr_reader :shared_folder_id
    def initialize(attrs={})
      @shared_folder_id = attrs.delete('shared_folder_id')
      super(attrs)
    end
  end
end
