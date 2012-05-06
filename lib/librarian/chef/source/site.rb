require 'fileutils'
require 'pathname'
require 'uri'
require 'net/http'
require 'json'
require 'digest'
require 'zlib'
require 'archive/tar/minitar'

require 'librarian/helpers/debug'

require 'librarian/chef/source/site/manifest'

module Librarian
  module Chef
    module Source
      class Site

        include Helpers::Debug

        class << self
          LOCK_NAME = 'SITE'
          def lock_name
            LOCK_NAME
          end
          def from_lock_options(environment, options)
            new(environment, options[:remote], options.reject{|k, v| k == :remote})
          end
        end

        attr_accessor :environment
        private :environment=
        attr_reader :uri

        attr_accessor :_metadata_cache
        private :_metadata_cache, :_metadata_cache=

        def initialize(environment, uri, options = {})
          self.environment = environment
          @uri = uri
          @cache_path = nil
          self._metadata_cache = { }
        end

        def to_s
          uri
        end

        def ==(other)
          other &&
          self.class  == other.class &&
          self.uri    == other.uri
        end

        def to_spec_args
          [uri, {}]
        end

        def to_lock_options
          {:remote => uri}
        end

        def pinned?
          false
        end

        def unpin!
        end

        def cache!(names)
          cache_path.mkpath
          names.each do |name|
            cache_metadata!(name)
          end
        end

        # NOTE:
        #   Assumes the Opscode Site API responds with versions in reverse sorted order
        def manifests(name)
          metadata = JSON.parse(metadata_cache_path(name).read)
          metadata['versions'].map{|version_uri| Manifest.new(self, name, version_uri)}
        end

        def manifest(name, version, dependencies)
          manifest = Manifest.new(self, name)
          manifest.version = version
          manifest.dependencies = dependencies
          manifest
        end

        def install_path(name)
          environment.install_path.join(name)
        end

        def cache_path
          @cache_path ||= begin
            dir = Digest::MD5.hexdigest(uri)
            environment.cache_path.join("source/chef/site/#{dir}")
          end
        end

        def dependency_cache_path(name)
          cache_path.join(name)
        end

        def metadata_cache_path(name)
          dependency_cache_path(name).join("metadata.json")
        end

        def version_cache_path(name, version_uri)
          dependency_cache_path(name).join(Digest::MD5.hexdigest(version_uri))
        end

        def version_metadata_cache_path(name, version_uri)
          version_cache_path(name, version_uri).join("version.json")
        end

        def version_archive_cache_file(name, version_uri)
          Pathname.new("archive.tgz")
        end

        def version_archive_cache_path(name, version_uri)
          version_archive_cache_file = version_archive_cache_file(name, version_uri)
          version_cache_path(name, version_uri).join(version_archive_cache_file)
        end

        def version_unpacked_cache_file(name, version_uri)
          Pathname.new(name)
        end

        def version_unpacked_cache_path(name, version_uri)
          version_unpacked_cache_file = version_unpacked_cache_file(name, version_uri)
          version_cache_path(name, version_uri).join(version_unpacked_cache_file)
        end

        def version_package_cache_file(name, version_uri)
          Pathname.new("package")
        end

        def version_package_cache_path(name, version_uri)
          version_package_cache_file = version_package_cache_file(name, version_uri)
          version_cache_path(name, version_uri).join(version_package_cache_file)
        end

        def dependency_uri(name)
          "#{uri}/cookbooks/#{name}"
        end

        def cache_metadata!(name)
          dependency_cache_path = cache_path.join(name)
          dependency_cache_path.mkpath
          metadata_cache_path = metadata_cache_path(name)

          caching_metadata(name) do
            dep_uri = URI.parse(dependency_uri(name))
            debug { "Caching #{dep_uri}" }
            http = Net::HTTP.new(dep_uri.host, dep_uri.port)
            request = Net::HTTP::Get.new(dep_uri.path)
            response = http.start{|http| http.request(request)}
            unless Net::HTTPSuccess === response
              raise Error, "Could not cache #{name} from #{dep_uri} because #{response.code} #{response.message}!"
            end
            metadata_blob = response.body
            JSON.parse(metadata_blob) # check that it's JSON
            metadata_cache_path(name).open('wb') do |f|
              f.write(metadata_blob)
            end
          end
        end

        def caching_metadata(name)
          _metadata_cache[name] = yield unless _metadata_cache.include?(name)
          _metadata_cache[name]
        end

        def cache_version_metadata!(name, version_uri)
          version_cache_path = version_cache_path(name, version_uri)
          unless version_cache_path.exist?
            version_cache_path.mkpath
            debug { "Caching #{version_uri}" }
            version_metadata_blob = Net::HTTP.get(URI.parse(version_uri))
            JSON.parse(version_metadata_blob) # check that it's JSON
            version_metadata_cache_path(name, version_uri).open('wb') do |f|
              f.write(version_metadata_blob)
            end
          end
        end

        def cache_version_package!(name, version_uri, file_uri)
          version_archive_cache_path = version_archive_cache_path(name, version_uri)
          unless version_archive_cache_path.exist?
            version_archive_cache_path.open('wb') do |f|
              f.write(Net::HTTP.get(URI.parse(file_uri)))
            end
          end
          version_package_cache_path = version_package_cache_path(name, version_uri)
          unless version_package_cache_path.exist?
            dependency_cache_path = dependency_cache_path(name)
            version_unpacked_temp_path = dependency_cache_path.join(name)
            Zlib::GzipReader.open(version_archive_cache_path) do |input|
              Archive::Tar::Minitar.unpack(input, version_unpacked_temp_path.to_s)
            end
            FileUtils.move(version_unpacked_temp_path.join(name), version_package_cache_path)
          end
        end

      end
    end
  end
end
