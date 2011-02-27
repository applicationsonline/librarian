require 'librarian/source'
require 'librarian/chef/source/site'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source

      class Path < Librarian::Source::Path
        include Particularity
      end

      class Git < Librarian::Source::Git
        include Particularity
      end

    end
  end
end
