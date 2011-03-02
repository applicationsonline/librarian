require 'uri'
require 'net/http'
require 'json'

require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source
      class Site

        include Particularity

        attr_reader :uri

        def initialize(uri, options = {})
          @uri = uri
          @cache_path = nil
        end

        def cache!(*dependencies)
          cache_path.rmtree if cache_path.exist?
          cache_path.mkpath
          dependencies.each do |dep|
            download!(dep)
          end
        end

        def install!(dependency)
          cache_path = dependency_cache_path(dependency)
          metadata = JSON.parse(metadata_cache_path(dependency).read)
          version_uri = metadata['latest_version']
          archive_file = version_archive_cache_file(dependency, version_uri)
          Dir.chdir(cache_path) do
            # version_unpacked_cache_path is where this gets extracted to
            `tar -xzf #{archive_file}`
          end
          install_path = install_path(dependency)
          install_path.rmtree if install_path.exist?
          unpacked_path = version_unpacked_cache_path(dependency, version_uri)
          FileUtils.cp_r(unpacked_path, install_path)
          unpacked_path.rmtree
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

        def dependency_uri(dependency)
          "#{uri}/cookbooks/#{dependency.name}"
        end

        def download!(dependency)
          dependency_cache_path = cache_path.join(dependency.name)
          dependency_cache_path.mkpath
          dep_uri = dependency_uri(dependency)
          metadata = JSON.parse(Net::HTTP.get(URI.parse(dep_uri)))
          metadata_cache_path(dependency).open('wb') do |f|
            f.write(JSON.dump(metadata))
          end
          metadata['versions'].map do |v|
            version = JSON.parse(Net::HTTP.get(URI.parse(v)))
            version_metadata_cache_path(dependency, v).open('wb') do |f|
              f.write(JSON.dump(version))
            end
            version_archive_cache_path(dependency, v).open('wb') do |f|
              f.write(Net::HTTP.get(URI.parse(version['file'])))
            end
          end
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
