require 'librarian/chef/manifest_reader'
require 'librarian/chef/source/local/manifest'

module Librarian
  module Chef
    module Source
      module Local

        def manifest_class
          Manifest
        end

      private

        def manifest?(name, path)
          ManifestReader.manifest?(name, path)
        end

      end
    end
  end
end
