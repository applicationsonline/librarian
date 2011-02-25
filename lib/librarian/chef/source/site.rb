require 'uri'
require 'net/http'
require 'json'

module Librarian
  module Chef
    module Source
      class Site

        attr_reader :uri

        def initialize(uri, options = {})
          @uri = uri
        end

        def cache!(dependencies)
          metadata_cache_path.rmtree if metadata_cache_path.exist?
          metadata_cache_path.mkpath
          dependencies.each do |dep|
            download!(dep)
          end
        end

        def install!(dependency)
          dependency_cache_path = metadata_cache_path.join(dependency.name)
          metadata = JSON.parse(dependency_cache_path.join("metadata.json").read)
          unpacked_dir = "version-#{Digest::MD5.hexdigest(metadata['latest_version'])}"
          archive_file = unpacked_dir + ".tgz"
          Dir.chdir(dependency_cache_path) do
            `tar -xzf #{archive_file}`
          end
          install_path = Librarian.install_path.join(dependency.name)
          install_path.rmtree if install_path.exist?
          FileUtils.cp_r(dependency_cache_path.join(dependency.name), install_path)
          dependency_cache_path.join(dependency.name).rmtree
        end

        def metadata_cache_path
          @metadata_cache_path ||= begin
            dir = Digest::MD5.hexdigest(uri)
            Librarian.cache_path.join("source/chef/site/#{dir}")
          end
        end

        def dependency_uri(dependency)
          "#{uri}/cookbooks/#{dependency.name}"
        end

        def download!(dependency)
          dependency_cache_path = metadata_cache_path.join(dependency.name)
          dependency_cache_path.mkpath
          dep_uri = dependency_uri(dependency)
          metadata = JSON.parse(Net::HTTP.get(URI.parse(dep_uri)))
          dependency_cache_path.join("metadata.json").open('wb') do |f|
            f.write(JSON.dump(metadata))
          end
          metadata['versions'].map do |v|
            version = JSON.parse(Net::HTTP.get(URI.parse(v)))
            version_file = "version-#{Digest::MD5.hexdigest(v)}.json"
            dependency_cache_path.join(version_file).open('wb') do |f|
              f.write(JSON.dump(version))
            end
            archive_file = "version-#{Digest::MD5.hexdigest(v)}.tgz"
            dependency_cache_path.join(archive_file).open('wb') do |f|
              f.write(Net::HTTP.get(URI.parse(version['file'])))
            end
          end
        end

      private

        def relative_path_to(path)
          Librarian.project_relative_path_to(path)
        end

        def debug
          Librarian.ui.debug "[Librarian] #{yield}"
        end

      end
    end
  end
end
