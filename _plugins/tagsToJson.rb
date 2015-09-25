module Jekyll
  class PostsByTagJson < Liquid::Tag
    def render(context)
      reg = context.registers
      site = reg[:site]
      tags = site.tags.keys

      output = tags.inject({}) do |memo, tag|
        memo[tag] = []
        memo
      end

      site.posts.reverse.each do |post|
        post.tags.each do |tag|
          output[tag] << {
            title: post.title,
            url: site.config["url"] + post.url,
            date: post.date,
          }
        end
      end

      output.to_json
    end
  end
end

Liquid::Template.register_tag('postsByTagJson', Jekyll::PostsByTagJson)
