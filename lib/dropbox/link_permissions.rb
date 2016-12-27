module Dropbox
  class Visibility
    attr_reader :tag

    def initialize(attrs={})
      @tag = attrs['.tag']
    end
  end

  class SharedLinkAccessFailureReason
    attr_reader :tag

    def initialize(attrs={})
      @tag = attrs['.tag']
    end
  end

  class LinkPermissions
    attr_reader :can_revoke, :resolved_visibility, :requested_visibility, :revoke_failure_reason

    def initialize(attrs={})
      @can_revoke = attrs['can_revoke']
      if visibility = attrs.delete('resolved_visibility')
        @resolved_visibility = visibility
      end
      if visibility = attrs.delete('requested_visibility')
        @requested_visibility = visibility
      end
      if reason = attrs.delete('revoke_failure_reason')
        @revoke_failure_reason = reason
      end
    end
  end
end
