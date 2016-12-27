module Dropbox
  class Team
    attr_reader :id, :name

    def initialize(attrs={})
      @id = attrs['id']
      @name = attrs['name']
    end
  end

  class TeamMemberInfo
    attr_reader :team_info, :display_name, :memeber_id

    def initialize(attrs={})
      @team_info = Team.new(attrs['team_info'])
      @display_name = attrs['display_name']
      @member_id = attrs['member_id']
    end
  end
end
