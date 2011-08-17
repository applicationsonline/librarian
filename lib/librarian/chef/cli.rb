require 'librarian/helpers'

require 'librarian/cli'
require 'librarian/chef'
require 'librarian/chef/particularity'

module Librarian
  module Chef
    class Cli < Librarian::Cli

      include Particularity
      extend Particularity

      source_root Pathname.new(__FILE__).dirname.join("templates")

      def init
        copy_file root_module.specfile_name
      end

    end
  end
end
