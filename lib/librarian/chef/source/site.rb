require 'fileutils'
require 'pathname'
require 'uri'
require 'net/http'
require 'json'
require 'digest'

require 'librarian/helpers/debug'

require 'librarian/manifest'
require 'librarian/chef/manifest'

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
              source.cache!([self])
              source.manifests(self).find{|m| m.version == version}.version_uri
            end
          end

          def version_uri=(version_uri)
            @version_uri = version_uri
          end

          def cache_path
            @cache_path ||= source.version_cache_path(self, version_uri)
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
            source.cache_version_metadata!(self, version_uri)
            JSON.parse(metadata_cache_path.read)
          end

          def version_manifest
            @version_manifest ||= fetch_version_manifest!
          end

          def fetch_version_manifest!
            source.cache_version_package!(self, version_uri, version_metadata['file'])
            manifest_path = manifest_path(package_cache_path)
            read_manifest(name, manifest_path)
          end

          def install!
            debug { "Installing #{self}" }
            version_manifest # make sure it's cached
            if install_path.exist?
              debug { "Deleting #{relative_path_to(install_path)}" }
              install_path.rmtree
            end
            package_cache_path = source.version_package_cache_path(self, version_uri)
            debug { "Copying #{relative_path_to(package_cache_path)} to #{relative_path_to(install_path)}" }
            FileUtils.cp_r(package_cache_path, install_path)
          end

        end

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

        def initialize(environment, uri, options = {})
          self.environment = environment
          @uri = uri
          @cache_path = nil
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

        def cache!(dependencies)
          cache_path.mkpath
          dependencies.each do |dependency|
            cache_metadata!(dependency)
          end
        end

        # NOTE:
        #   Assumes the Opscode Site API responds with versions in reverse sorted order
        def manifests(dependency)
          metadata = JSON.parse(metadata_cache_path(dependency).read)
          metadata['versions'].map{|version_uri| Manifest.new(self, dependency.name, version_uri)}
        end

        def manifest(name, version, dependencies)
          manifest = Manifest.new(self, name)
          manifest.version = version
          manifest.dependencies = dependencies
          manifest
        end

        def install_path(dependency)
          environment.install_path.join(dependency.name)
        end

        def cache_path
          @cache_path ||= begin
            dir = Digest::MD5.hexdigest(uri)
            environment.cache_path.join("source/chef/site/#{dir}")
          end
        end

        def dependency_cache_path(dependency)
          cache_path.join(dependency.name)
        end

        def metadata_cache_path(dependency)
          dependency_cache_path(dependency).join("metadata.json")
        end

        def version_cache_path(dependency, version_uri)
          dependency_cache_path(dependency).join(Digest::MD5.hexdigest(version_uri))
        end

        def version_metadata_cache_path(dependency, version_uri)
          version_cache_path(dependency, version_uri).join("version.json")
        end

        def version_archive_cache_file(dependency, version_uri)
          Pathname.new("archive.tgz")
        end

        def version_archive_cache_path(dependency, version_uri)
          version_archive_cache_file = version_archive_cache_file(dependency, version_uri)
          version_cache_path(dependency, version_uri).join(version_archive_cache_file)
        end

        def version_unpacked_cache_file(dependency, version_uri)
          Pathname.new(dependency.name)
        end

        def version_unpacked_cache_path(dependency, version_uri)
          version_unpacked_cache_file = version_unpacked_cache_file(dependency, version_uri)
          version_cache_path(dependency, version_uri).join(version_unpacked_cache_file)
        end

        def version_package_cache_file(dependency, version_uri)
          Pathname.new("package")
        end

        def version_package_cache_path(dependency, version_uri)
          version_package_cache_file = version_package_cache_file(dependency, version_uri)
          version_cache_path(dependency, version_uri).join(version_package_cache_file)
        end

        def dependency_uri(dependency)
          "#{uri}/cookbooks/#{dependency.name}"
        end

        def cache_metadata!(dependency)
          dependency_cache_path = cache_path.join(dependency.name)
          dependency_cache_path.mkpath
          metadata_cache_path = metadata_cache_path(dependency)
          unless metadata_cache_path.exist?
            dep_uri = URI.parse(dependency_uri(dependency))
            debug { "Caching #{dep_uri}" }
            http = Net::HTTP.new(dep_uri.host, dep_uri.port)
            request = Net::HTTP::Get.new(dep_uri.path)
            response = http.start{|http| http.request(request)}
            unless Net::HTTPSuccess === response
              raise Error, "Could not cache #{dependency} from #{dep_uri} because #{response.code} #{response.message}!"
            end
            metadata_blob = response.body
            JSON.parse(metadata_blob) # check that it's JSON
            metadata_cache_path(dependency).open('wb') do |f|
              f.write(metadata_blob)
            end
          end
        end

        def cache_version_metadata!(dependency, version_uri)
          version_cache_path = version_cache_path(dependency, version_uri)
          unless version_cache_path.exist?
            version_cache_path.mkpath
            debug { "Caching #{version_uri}" }
            version_metadata_blob = Net::HTTP.get(URI.parse(version_uri))
            JSON.parse(version_metadata_blob) # check that it's JSON
            version_metadata_cache_path(dependency, version_uri).open('wb') do |f|
              f.write(version_metadata_blob)
            end
          end
        end

        def cache_version_package!(dependency, version_uri, file_uri)
          version_archive_cache_path = version_archive_cache_path(dependency, version_uri)
          unless version_archive_cache_path.exist?
            version_archive_cache_path.open('wb') do |f|
              f.write(Net::HTTP.get(URI.parse(file_uri)))
            end
          end
          version_package_cache_path = version_package_cache_path(dependency, version_uri)
          unless version_package_cache_path.exist?
            dependency_cache_path = dependency_cache_path(dependency)
            Process.waitpid2(fork do
              $stdin.reopen("/dev/null")
              $stdout.reopen("/dev/null")
              $stderr.reopen("/dev/null")
              Dir.chdir(dependency_cache_path)
              exec("tar", "-xzf", version_archive_cache_path.to_s)
            end)
            raise StandardError, "Caching #{version_uri} failed with #{$?.inspect}!" unless $?.success?
            version_unpacked_temp_path = dependency_cache_path.join(dependency.name)
            FileUtils.move(version_unpacked_temp_path, version_package_cache_path)
          end
        end

      end
    end
  end
end
