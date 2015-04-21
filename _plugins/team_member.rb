module Jekyll
  module TeamMemberFilter

    # Add our new liquid filter.
    def team_members(authors)
      return [] if authors.nil?

      authors = authors.map do |github_username|
        load_data(github_username.downcase)
      end

      authors
    end

    def team_member(github_username)
      load_data(github_username.downcase)
    end

    private

    def load_data(github_username)
      filePath = File.join('_data', 'team', "#{github_username}.yml")
      data     = SafeYAML.load_file(filePath)
      data
    end

  end
end

Liquid::Template.register_filter(Jekyll::TeamMemberFilter)
