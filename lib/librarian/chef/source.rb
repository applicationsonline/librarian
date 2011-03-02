require 'librarian/source'
require 'librarian/chef/source/local'
require 'librarian/chef/source/site'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source

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
