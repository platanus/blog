# you should add something like this to your config:
# remote_layout_url: remote_layout_url-name
require 'open-uri'

module Jekyll
  class LayoutChooser < Generator
    safe false

    def generate(site)
      #themes_path = '_themes/'
      #target_path = site.config['source'] + '/_layouts'
      #unless site.config['remote_layout_url'] then
        #unless (Dir.entries(target_path).size - 2 > 0) then
          #STDERR.puts 'theme parameter is not set. The _layouts directory is not empty. Theme will not be generated.'
          #return
        #end
        #puts "theme parameter is not set. Using _layouts directory. The plugin will now exit."
        #return
      #end
#
      #theme = File.join(themes_path, site.config['theme'])
      #unless FileTest.directory?(theme) then
        #STDERR.puts "Theme directory #{theme} not found. Theme will not be generated."
        #return
      #end
#
#
      remote_layouts_url = site.config['remote_layout_url']
      remote_layouts = site.config['remote_layouts']

      remote_layouts.each do |layout_name|
        begin
          source = remote_layouts_url + "/" + layout_name
          layout = open(source).read

          begin
            destination = File.join(site.config['source'], site.config['layouts'], layout_name + '.html')
            open(destination, 'wb') do |file|
              file << layout
            end
          rescue
            puts "Layout couldn't be written to: " + destination
          end

        rescue
          puts "Layout not found at: " + source
        end
      end

      #print "Copying theme '#{site.config['theme']}'.."
      #FileUtils.cp_r(Dir.getwd + '/' + theme + '/.', target_path)
      #puts "."
      site.read_layouts
      #puts "done."
    end
  end
end