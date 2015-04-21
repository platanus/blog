module Jekyll
  module ToArrayFilter

    # Add our new liquid filter.
    def toArray(input)
      [input]
    end

  end
end

Liquid::Template.register_filter(Jekyll::ToArrayFilter)
