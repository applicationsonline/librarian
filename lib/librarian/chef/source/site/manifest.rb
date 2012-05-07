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
          attr_reader :install_path

          def initialize(source, name, version_uri = nil)
            super(source, name)
            @version_uri = version_uri

            @cache_path = nil
            @metadata_cache_path = nil
            @package_cache_path = nil
            @install_path = environment.install_path.join(name)

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
            @version_uri ||= begin
              source.cache!([name])
              source.manifests(name).find{|m| m.version == version}.version_uri
            end
          end

          def version_uri=(version_uri)
            @version_uri = version_uri
          end

          def cache_path
            @cache_path ||= source.version_cache_path(name, version_uri)
          end
          def metadata_cache_path
            @metadata_cache_path ||= cache_path.join('version.json')
          end
          def package_cache_path
            @package_cache_path ||= cache_path.join('package')
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

          def install!
            debug { "Installing #{self}" }
            version_manifest # make sure it's cached
            if install_path.exist?
              debug { "Deleting #{relative_path_to(install_path)}" }
              install_path.rmtree
            end
            package_cache_path = source.version_package_cache_path(name, version_uri)
            debug { "Copying #{relative_path_to(package_cache_path)} to #{relative_path_to(install_path)}" }
            FileUtils.cp_r(package_cache_path, install_path)
          end

        end
      end
    end
  end
end
