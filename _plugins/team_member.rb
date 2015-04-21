module Jekyll
  module TeamMemberFilter

    # Add our new liquid filter.
    def team_member(authors)
      return [] if authors.nil?

      authors = authors.map do |github_username|
        filePath = File.join('_data', 'team', "#{github_username.downcase}.yml")
        data     = SafeYAML.load_file(filePath)
        data
      end

      authors
    end

  end
end

Liquid::Template.register_filter(Jekyll::TeamMemberFilter)
