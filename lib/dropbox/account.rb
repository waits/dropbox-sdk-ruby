module Dropbox
  class Account
    attr_reader :account_id, :display_name, :email, :email_verified, :disabled, :profile_photo_url

    def initialize(attrs={})
      @account_id = attrs['account_id']
      @display_name = attrs['name']['display_name']
      @email = attrs['email']
      @email_verified = attrs['email_verified']
      @disabled = attrs['disabled']
      @profile_photo_url = attrs['profile_photo_url']
    end
  end

  class BasicAccount < Account
    attr_reader :is_teammate, :team_member_id

    def initialize(attrs={})
      @is_teammate = attrs.delete('is_teammate')
      @team_member_id = attrs.delete('team_member_id')
      super(attrs)
    end
  end

  class FullAccount < Account
    attr_reader :locale, :referral_link, :is_paired, :profile_photo_url, :country

    def initialize(attrs={})
      @locale = attrs.delete('locale')
      @referral_link = attrs.delete('referral_link')
      @is_paired = attrs.delete('is_paired')
      @profile_photo_url = attrs.delete('profile_photo_url')
      @country = attrs.delete('country')
      super(attrs)
    end
  end

  class SpaceUsage
    attr_reader :used, :allocation, :allocated

    def initialize(attrs={})
      @used = attrs['used'] # Space used in bytes
      @allocation = attrs['allocation']['.tag'] # The type of allocation
      @allocated = attrs['allocation']['allocated'] # Space allocated in bytes
    end
  end
end
