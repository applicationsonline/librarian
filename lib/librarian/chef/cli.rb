require 'librarian/cli'
require 'librarian/chef'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    class Cli < Librarian::Cli

      include Particularity
      extend Particularity

    end
  end
end
