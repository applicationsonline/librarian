require "librarian/dependency"

module Librarian
  module Chef
    module Source
      class Site
        class Manifest < Manifest

          attr_reader :version_uri

          def fetch_version!
            version_metadata['version']
          end

          def fetch_dependencies!
            version_manifest['dependencies'].map{|k, v| Dependency.new(k, v, nil)}
          end

          def version_uri
            extra[:version_uri] ||= source.find_version_uri(name, version)
          end

          def version_uri=(version_uri)
            extra[:version_uri] = version_uri
          end

          def cache_path
            source.version_cache_path(name, version_uri)
          end
          def metadata_cache_path
            source.version_metadata_cache_path(name, version_uri)
          end
          def package_cache_path
            source.version_package_cache_path(name, version_uri)
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
