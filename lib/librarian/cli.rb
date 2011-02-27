require 'thor'
require 'thor/actions'
require 'librarian'

module Librarian
  class Cli < Thor

    include Thor::Actions
    include Particularity
    extend Particularity

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      root_module.ui = UI::Shell.new(the_shell)
      root_module.ui.debug! if options["verbose"]
    end

    class << self
      def bin!
        begin
          start
        rescue Librarian::Error => e
          root_module.ui.error e.message
          root_module.ui.debug e.backtrace.join("\n")
          exit (e.respond_to?(:status_code) ? e.status_code : 1)
        rescue Interrupt => e
          root_module.ui.error "\nQuitting..."
          root_module.ui.debug e.backtrace.join("\n")
          exit 1
        end
      end
    end

  end
end
