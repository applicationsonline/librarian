require 'librarian/cli'
require 'librarian/mock'
require 'librarian/mock/particularity'

module Librarian
  module Mock
    class Cli < Librarian::Cli

      include Particularity
      extend Particularity

    end
  end
end
