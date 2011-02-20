require 'thor'
require 'thor/actions'
require 'librarian/ui'

module Librarian
  class Cli < Thor

    include Thor::Actions

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      Librarian.ui = UI::Shell.new(the_shell)
      Librarian.ui.debug! if options["verbose"]
    end

    desc "clean", "Cleans out the cache and install paths."
    def clean
      Librarian.ensure!
      Librarian.clean!
    end

    desc "install", "Installs all of the cookbooks you specify."
    def install
      Librarian.ensure!
      Librarian.install!
    end

  end
end
