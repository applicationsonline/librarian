require 'librarian/manifest'

module Librarian
  module Chef
    module Source
      module Local
        class Manifest < Manifest

          def fetch_version!
            source.fetch_version(name, extra)
          end

          def fetch_dependencies!
            source.fetch_dependencies(name, version, extra)
          end

        end
      end
    end
  end
end
