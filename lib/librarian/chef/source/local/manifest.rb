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
            @found_path = nil
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

          def install!
            debug { "Installing #{name}-#{version}" }
            install_path = environment.install_path.join(name)
            if install_path.exist?
              debug { "Deleting #{relative_path_to(install_path)}" }
              install_path.rmtree
            end
            debug { "Copying #{relative_path_to(found_path)} to #{relative_path_to(install_path)}" }
            FileUtils.cp_r(found_path, install_path)
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
