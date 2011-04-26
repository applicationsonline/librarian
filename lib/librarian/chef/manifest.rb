require 'json'
require 'yaml'

require 'librarian/manifest'

module Librarian
  module Chef
    class Manifest < Manifest

      module Helpers

        MANIFESTS = %w(metadata.json metadata.yml metadata.yaml metadata.rb)

        def manifest_path(path)
          MANIFESTS.map{|s| path.join(s)}.find{|s| s.exist?}
        end

        def read_manifest(name, manifest_path)
          case manifest_path.extname
          when ".json" then JSON.parse(manifest_path.read)
          when ".yml", ".yaml" then YAML.load(manifest_path.read)
          when ".rb" then compile_manifest(name, manifest_path.dirname) ; read_manifest(name, manifest_path(manifest_path.dirname))
          end
        end

        def compile_manifest(name, path)
          # Inefficient, if there are many cookbooks with uncompiled metadata.
          require 'chef/cookbook/metadata'
          md = ::Chef::Cookbook::Metadata.new
          md.name(name)
          md.from_file(path.join('metadata.rb'))
          json_file = path.join('metadata.json')
          json_file.open('wb') { |f| f.write(::Chef::JSONCompat.to_json_pretty(md)) }
        end

      end

      include Helpers
      extend Helpers

    end
  end
end
