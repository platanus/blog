require 'open-uri'
require 'json'
require 'yaml'

module Jekyll
  class Data < Generator
    def generate(site)
      data_path = File.join(site.config['source'], site.config['data_source'])
      resources = site.config['data_fetch_resources']

      resources.each do |r|
        url = r['url']
        name = r['name']
        item_name_key = r['item_name_key']

        data = JSON.parse(open(url).read)

        data.each do |item|
          next unless item['develops']

          item_name = item[item_name_key]
          destination_path = File.join(data_path, name)
          destination_file = File.join(destination_path, item_name.downcase + '.yml')

          unless File.exist?(destination_path)
            FileUtils.mkdir_p(destination_path)
          end

          open(destination_file, 'wb') do |file|
            file << YAML::dump(item)
          end
        end

      end
    end
  end
end
