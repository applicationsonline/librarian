require 'fileutils'
require 'pathname'

require 'librarian/chef/manifest_reader'

module Librarian
  module Chef
    module Source
      module Local
        class Manifest < Manifest

          def manifest
            source.manifest_data(name)
          end

          def fetch_version!
            manifest['version']
          end

          def fetch_dependencies!
            manifest['dependencies']
          end

        end
      end
    end
  end
end
