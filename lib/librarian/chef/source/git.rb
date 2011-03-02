require 'librarian/source/git'
require 'librarian/chef/source/local'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    module Source
      class Git < Librarian::Source::Git
        include Particularity
        include Local
      end
    end
  end
end
