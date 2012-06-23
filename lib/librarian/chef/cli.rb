require 'librarian/helpers'

require 'librarian/cli'
require 'librarian/chef'

module Librarian
  module Chef
    class Cli < Librarian::Cli

      module Particularity
        def root_module
          Chef
        end
      end

      include Particularity
      extend Particularity

      source_root Pathname.new(__FILE__).dirname.join("templates")

      def init
        copy_file environment.specfile_name
      end

      desc "install", "Resolves and installs all of the dependencies you specify."
      option "verbose"
      option "line-numbers"
      option "clean"
      option "strip-dot-git", :type => :boolean
      def install
        ensure!
        clean! if options["clean"]
        if options.include?("strip-dot-git")
          strip_dot_git_val = options["strip-dot-git"] ? "1" : nil
          environment.config_db.local["install.strip-dot-git"] = strip_dot_git_val
        end
        resolve!
        install!
      end

    end
  end
end
