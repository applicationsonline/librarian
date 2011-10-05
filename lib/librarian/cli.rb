require 'thor'
require 'thor/actions'
require 'librarian'

module Librarian
  class Cli < Thor

    include Thor::Actions
    include Particularity
    extend Particularity

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
          exit 1
        end
      end
    end

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      root_module.ui = UI::Shell.new(the_shell)
      root_module.ui.debug! if options["verbose"]
      root_module.ui.debug_line_numbers! if options["verbose"] && options["line-numbers"]
    end

    desc "version", "Displays the version."
    def version
      say "librarian-#{root_module.version}"
    end

    desc "clean", "Cleans out the cache and install paths."
    method_option "verbose"
    method_option "line-numbers"
    def clean
      root_module.ensure!
      root_module.clean!
    end

    desc "install", "Installs all of the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    method_option "clean"
    def install
      root_module.ensure!
      root_module.clean! if options["clean"]
      root_module.install!
    end

    desc "resolve", "Resolves the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    method_option "clean"
    def resolve
      root_module.ensure!
      root_module.clean! if options["clean"]
      root_module.resolve!
    end

    desc "update", "Updates the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    def update(*names)
      root_module.ensure!
      if names.empty?
        root_module.resolve!(:force => true)
      else
        root_module.update!(names)
      end
    end

    desc "init", "Initializes the current directory."
    def init
      puts "Nothing to do."
    end

  end
end
