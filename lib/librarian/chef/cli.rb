require 'librarian/cli'
require 'librarian/chef'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    class Cli < Librarian::Cli

      include Particularity
      extend Particularity

      desc "clean", "Cleans out the cache and install paths."
      def clean
        root_module.ensure!
        root_module.clean!
      end

      desc "install", "Installs all of the cookbooks you specify."
      def install
        root_module.ensure!
        root_module.install!
      end

    end
  end
end
