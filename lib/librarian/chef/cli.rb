require 'librarian/chef/particularity'
require 'librarian/cli'

module Librarian
  module Chef
    class Cli < Librarian::Cli

      include Particularity

      desc "clean", "Cleans out the cache and install paths."
      def clean
        Librarian::Chef.ensure!
        Librarian::Chef.clean!
      end

      desc "install", "Installs all of the cookbooks you specify."
      def install
        Librarian::Chef.ensure!
        Librarian::Chef.install!
      end

    end
  end
end
