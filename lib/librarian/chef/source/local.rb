require 'librarian/chef/manifest_reader'
require 'librarian/chef/source/local/manifest'

module Librarian
  module Chef
    module Source
      module Local

        def manifest_class
          Manifest
        end

        def install!(manifest)
          manifest.source == self or raise ArgumentError

          debug { "Installing #{manifest}" }

          name, version = manifest.name, manifest.version
          found_path = found_path(name)

          install_path = environment.install_path.join(name)
          if install_path.exist?
            debug { "Deleting #{relative_path_to(install_path)}" }
            install_path.rmtree
          end

          debug { "Copying #{relative_path_to(found_path)} to #{relative_path_to(install_path)}" }
          FileUtils.cp_r(found_path, install_path)
        end

      private

        def manifest?(name, path)
          ManifestReader.manifest?(name, path)
        end

      end
    end
  end
end
