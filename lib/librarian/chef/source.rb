require 'pathname'
require 'json'
require 'yaml'

require 'librarian/source'
require 'librarian/manifest'
require 'librarian/chef/source/site'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source

      module Local

        class Manifest < Librarian::Manifest

          class << self

            MANIFESTS = %w(metadata.json metadata.yml metadata.yaml)

            def create(path)
              manifest?(path) ? new(path) : nil
            end

            def manifest?(dependency, path)
              path = Pathname.new(path)
              manifest_path = manifest_path(path)
              manifest_path && check_manifest(dependency, manifest_path)
            end

          private

            def manifest_path(path)
              MANIFESTS.map{|s| path.join(s)}.find{|s| s.exist?}
            end

            def read_manifest(manifest_path)
              case manifest_path.extname
              when ".json" then JSON.parse(manifest_path.read)
              when ".yml", ".yaml" then YAML.load(manifest_path.read)
              end
            end

            def check_manifest(dependency, manifest_path)
              manifest = read_manifest(manifest_path)
              manifest["name"] = dependency.name
            end

          end

          attr_reader :path, :manifest_path

          def initialize(path)
            path = Pathname.new(path)
            manifest_path = self.class.manifest_path(path)
            manifest = self.class.read_manifest(manifest_path)
            name = manifest["name"]
            version = manifest["version"]
            dependencies = manifest["dependencies"]
            super(name, version, dependencies)
            @path, @manifest_path = path, manifest_path
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
