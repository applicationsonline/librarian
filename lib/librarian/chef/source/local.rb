require 'librarian/chef/source/local/manifest'

module Librarian
  module Chef
    module Source
      module Local

        def manifest_class
          Manifest
        end

      end
    end
  end
end
