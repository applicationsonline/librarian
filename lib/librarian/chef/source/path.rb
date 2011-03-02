require 'librarian/source/path'
require 'librarian/chef/source/local'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source
      class Path < Librarian::Source::Path
        include Particularity
        include Local
      end
    end
  end
end
