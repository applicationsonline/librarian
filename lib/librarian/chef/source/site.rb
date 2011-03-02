require 'fileutils'
require 'pathname'
require 'uri'
require 'net/http'
require 'json'
require 'yaml'
require 'digest'

require 'librarian/manifest'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source
      class Site

        class Manifest < Librarian::Manifest

          MANIFESTS = %w(metadata.json metadata.yml metadata.yaml)

          attr_reader :version_uri

          def initialize(source, name, version_uri)
            super(source, name)
            @version_uri = version_uri
            @version_metadata, @version = nil, nil
            @version_manifest, @dependencies = nil, nil
          end

          def cache_version!
            version_metadata['version']
          end

          def cache_dependencies!
            version_manifest['dependencies'].map{|k, v| Dependency.new(k, v, nil)}
          end

          def version_metadata
            @version_metadata ||= cache_version_metadata!
          end

          def cache_version_metadata!
            source.cache_version_metadata!(self, version_uri)
            path = source.version_metadata_cache_path(self, version_uri)
            JSON.parse(path.read)
          end

          def version_manifest
            @version_manifest ||= cache_version_manifest!
          end

          def cache_version_manifest!
            source.cache_version_package!(self, version_uri, version_metadata['file'])
            package_cache_path = source.version_package_cache_path(self, version_uri)
            manifest_path = MANIFESTS.map{|p| package_cache_path.join(p)}.find{|p| p.exist?}
            read_manifest(manifest_path)
          end

          def read_manifest(manifest_path)
            case manifest_path.extname
            when ".json" then JSON.parse(manifest_path.read)
            when ".yml", ".yaml" then YAML.load(manifest_path.read)
            end
          end

        end

        include Particularity

        attr_reader :uri

        def initialize(uri, options = {})
          @uri = uri
          @cache_path = nil
        end

        def cache!(dependencies)
          cache_path.mkpath
          dependencies.each do |dependency|
            cache_metadata!(dependency)
          end
        end

        def install!(manifest)
          install_path = install_path(manifest)
          install_path.rmtree if install_path.exist?
          package_path = version_package_cache_path(manifest, manifest.version_uri)
          FileUtils.cp_r(package_path, install_path)
        end

        # NOTE:
        #   Assumes the Opscode Site API responds with versions in reverse sorted order
        def manifests(dependency)
          metadata = JSON.parse(metadata_cache_path(dependency).read)
          metadata['versions'].map{|version_uri| Manifest.new(self, dependency.name, version_uri)}
        end

        def install_path(dependency)
          root_module.install_path.join(dependency.name)
        end

        def cache_path
          @cache_path ||= begin
            dir = Digest::MD5.hexdigest(uri)
            root_module.cache_path.join("source/chef/site/#{dir}")
          end
        end

        def dependency_cache_path(dependency)
          cache_path.join(dependency.name)
        end

        def metadata_cache_path(dependency)
          dependency_cache_path(dependency).join("metadata.json")
        end

        def version_metadata_cache_path(dependency, version_uri)
          dependency_cache_path(dependency).join("version-#{Digest::MD5.hexdigest(version_uri)}.json")
        end

        def version_archive_cache_file(dependency, version_uri)
          Pathname.new("version-#{Digest::MD5.hexdigest(version_uri)}.tgz")
        end

        def version_archive_cache_path(dependency, version_uri)
          dependency_cache_path(dependency).join(version_archive_cache_file(dependency, version_uri))
        end

        def version_unpacked_cache_file(dependency, version_uri)
          Pathname.new(dependency.name)
        end

        def version_unpacked_cache_path(dependency, version_uri)
          dependency_cache_path(dependency).join(version_unpacked_cache_file(dependency, version_uri))
        end

        def version_package_cache_file(dependency, version_uri)
          Pathname.new("version-#{Digest::MD5.hexdigest(version_uri)}")
        end

        def version_package_cache_path(dependency, version_uri)
          dependency_cache_path(dependency).join(version_package_cache_file(dependency, version_uri))
        end

        def dependency_uri(dependency)
          "#{uri}/cookbooks/#{dependency.name}"
        end

        def cache_metadata!(dependency)
          dependency_cache_path = cache_path.join(dependency.name)
          dependency_cache_path.mkpath
          dep_uri = dependency_uri(dependency)
          metadata_blob = Net::HTTP.get(URI.parse(dep_uri))
          metadata_cache_path(dependency).open('wb') do |f|
            f.write(metadata_blob)
          end
        end

        def cache_version_metadata!(dependency, version_uri)
          version_metadata_blob = Net::HTTP.get(URI.parse(version_uri))
          version_metadata_cache_path(dependency, version_uri).open('wb') do |f|
            f.write(version_metadata_blob)
          end
        end

        def cache_version_package!(dependency, version_uri, file_uri)
          dependency_cache_path = dependency_cache_path(dependency)
          version_archive_cache_path = version_archive_cache_path(dependency, version_uri)
          version_archive_cache_path.open('wb') do |f|
            f.write(Net::HTTP.get(URI.parse(file_uri)))
          end
          Dir.chdir(dependency_cache_path) do
            `tar -xzf #{version_archive_cache_path}`
          end
          version_unpacked_temp_path = dependency_cache_path.join(dependency.name)
          version_package_cache_path = version_package_cache_path(dependency, version_uri)
          FileUtils.move(version_unpacked_temp_path, version_package_cache_path)
        end

      private

        def relative_path_to(path)
          root_module.project_relative_path_to(path)
        end

        def debug
          root_module.ui.debug "[Librarian] #{yield}"
        end

      end
    end
  end
end
