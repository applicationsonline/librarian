require "fileutils"

require "json"

require "librarian/dependency"
require 'librarian/chef/manifest_reader'

module Librarian
  module Chef
    module Source
      class Site
        class Manifest < Manifest

          attr_reader :version_uri

          def initialize(source, name, extra = { })
            super(source, name, extra)

            @version_metadata = nil
            @version_manifest = nil
          end

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
            @version_metadata ||= fetch_version_metadata!
          end

          def fetch_version_metadata!
            source.cache_version_metadata!(name, version_uri)
            JSON.parse(metadata_cache_path.read)
          end

          def version_manifest
            @version_manifest ||= fetch_version_manifest!
          end

          def fetch_version_manifest!
            source.cache_version_package!(name, version_uri, version_metadata['file'])
            manifest_path = ManifestReader.manifest_path(package_cache_path)
            ManifestReader.read_manifest(name, manifest_path)
          end

        end
      end
    end
  end
end
