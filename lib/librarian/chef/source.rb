require 'pathname'

require 'librarian/source'
require 'librarian/manifest'
require 'librarian/chef/manifest'
require 'librarian/chef/source/site'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source

      module Local

        class Manifest < Manifest

          class << self

            def create(source, dependency, path)
              manifest?(dependency, path) ? new(source, dependency.name, path) : nil
            end

            def manifest?(dependency, path)
              path = Pathname.new(path)
              manifest_path = manifest_path(path)
              manifest_path && check_manifest(dependency, manifest_path)
            end

            def check_manifest(dependency, manifest_path)
              manifest = read_manifest(manifest_path)
              manifest["name"] == dependency.name
            end

          end

          attr_reader :path, :manifest_path

          def initialize(source, name, path)
            super(source, name)
            path = Pathname.new(path)
            manifest_path = self.class.manifest_path(path)
            @path, @manifest_path = path, manifest_path
          end

          def manifest
            @manifest ||= cache_manifest!
          end

          def cache_manifest!
            self.class.read_manifest(manifest_path)
          end

          def cache_version!
            manifest['version']
          end

          def cache_dependencies!
            manifest['dependencies']
          end

        end

        def manifest_class
          Manifest
        end

      end

      class Path < Librarian::Source::Path
        include Particularity
        include Local
      end

      class Git < Librarian::Source::Git
        include Particularity
        include Local
      end

    end
  end
end
