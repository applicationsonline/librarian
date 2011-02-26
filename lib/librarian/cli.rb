require 'thor'
require 'thor/actions'
require 'librarian/ui'
require 'librarian/particularity'

module Librarian
  class Cli < Thor

    include Thor::Actions
    include Particularity

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      root_module.ui = UI::Shell.new(the_shell)
      root_module.ui.debug! if options["verbose"]
    end

  end
end
