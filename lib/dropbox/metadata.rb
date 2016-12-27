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

  # Contains the metadata of a sharing content.
  module SharingMetadata
    def self.included(base)
      base.class_eval do
        attr_reader :url, :link_permissions, :expires, :team_member_info, :content_owner_team_info
      end
    end

    def initialize(attrs={})
      super(attrs)
      @url = attrs['url']
      @link_permissions = LinkPermissions.new(attrs['link_permissions'])
      if expires = attrs.delete('expires')
        @expires= Time.parse(expires)
      end
      if team_member_info = attrs.delete('team_member_info')
        @team_member_info = TeamMemberInfo.new(team_member_info)
      end
      if content_owner_team_info = attrs.delete('content_owner_team_info')
        @content_owner_team_info = TeamMemberInfo.new(content_owner_team_info)
      end
    end
  end

  # Contains the metadata of a shared file.
  class FileLinkMetadata < FileMetadata
    include SharingMetadata
  end

  # Contains the metadata of a shared folder.
  class FolderLinkMetadata < FolderMetadata
    include SharingMetadata
  end
end
