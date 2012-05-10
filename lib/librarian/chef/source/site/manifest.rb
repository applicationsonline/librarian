require "librarian/dependency"

module Librarian
  module Chef
    module Source
      class Site
        class Manifest < Manifest

          def fetch_version!
            version_metadata['version']
          end

          def fetch_dependencies!
            version_manifest['dependencies'].map{|k, v| Dependency.new(k, v, nil)}
          end

          def version_uri
            self.extra = extra || source.find_version_uri(name, version)
          end

          def version_uri=(version_uri)
            self.extra = version_uri
          end

          def version_metadata
            source.version_metadata(name, version_uri)
          end

          def version_manifest
            source.version_manifest(name, version_uri)
          end

        end
      end
    end
  end
end
