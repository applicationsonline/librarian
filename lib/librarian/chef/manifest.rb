require 'json'
require 'yaml'

require 'librarian/manifest'

module Librarian
  module Chef
    class Manifest < Manifest

      module Helpers

        MANIFESTS = %w(metadata.json metadata.yml metadata.yaml)

        def manifest_path(path)
          MANIFESTS.map{|s| path.join(s)}.find{|s| s.exist?}
        end

        def read_manifest(manifest_path)
          case manifest_path.extname
          when ".json" then JSON.parse(manifest_path.read)
          when ".yml", ".yaml" then YAML.load(manifest_path.read)
          end
        end

      end

      include Helpers
      extend Helpers

    end
  end
end
