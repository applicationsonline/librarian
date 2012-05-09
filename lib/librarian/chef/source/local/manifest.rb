require 'fileutils'
require 'pathname'

require 'librarian/chef/manifest_reader'

module Librarian
  module Chef
    module Source
      module Local
        class Manifest < Manifest

          attr_reader :path

          def initialize(source, name, path)
            super(source, name)
            @path = Pathname.new(path)
          end

          def found_path
            source.found_path(name)
          end

          def manifest
            @manifest ||= fetch_manifest!
          end

          def fetch_manifest!
            expect_manifest

            ManifestReader.read_manifest(name, ManifestReader.manifest_path(found_path))
          end

          def fetch_version!
            manifest['version']
          end

          def fetch_dependencies!
            manifest['dependencies']
          end

        private

          def expect_manifest
            return if found_path && ManifestReader.manifest_path(found_path)
            raise Error, "No metadata file found for #{name} from #{source}! If this should be a cookbook, you might consider contributing a metadata file upstream or forking the cookbook to add your own metadata file."
          end

        end
      end
    end
  end
end
