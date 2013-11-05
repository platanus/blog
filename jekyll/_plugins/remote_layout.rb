# you should add something like this to your config:
# remote_layout_url: remote_layout_url-name
require 'open-uri'

module Jekyll
  class LayoutChooser < Generator
    safe false

    def generate(site)
      remote_layouts_url = site.config['remote_layout_url']
      remote_layouts = site.config['remote_layouts']

      remote_layouts.each do |layout_name|
        begin
          source = remote_layouts_url + "/" + layout_name
          layout = open(source).read

          begin
            destination_file = File.join(site.config['source'], site.config['layouts'], layout_name + '.html')
            destination_path = File.dirname(destination_file)
            unless File.exist?(destination_path)
              FileUtils.mkdir_p(destination_path)
            end

            open(destination_file, 'wb') do |file|
              file << layout
            end
          rescue
            puts "Layout couldn't be written to: " + destination
          end

        rescue
          puts "Layout not found at: " + source
        end
      end

      site.read_layouts
    end
  end
end
