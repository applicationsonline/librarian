require 'thor'
require 'thor/actions'

require 'librarian'
require "librarian/ui"

module Librarian
  class Cli < Thor

    include Thor::Actions

    module Particularity
      def root_module
        nil
      end
    end

    include Particularity
    extend Particularity

    class << self
      def bin!
        begin
          environment = root_module.environment
          start
        rescue Librarian::Error => e
          environment.ui.error e.message
          environment.ui.debug e.backtrace.join("\n")
          exit (e.respond_to?(:status_code) ? e.status_code : 1)
        rescue Interrupt => e
          environment.ui.error "\nQuitting..."
          exit 1
        end
      end
    end

    def initialize(*)
      super
      the_shell = (options["no-color"] ? Thor::Shell::Basic.new : shell)
      environment.ui = UI::Shell.new(the_shell)
      environment.ui.debug! if options["verbose"]
      environment.ui.debug_line_numbers! if options["verbose"] && options["line-numbers"]
    end

    desc "version", "Displays the version."
    def version
      say "librarian-#{root_module.version}"
    end

    desc "clean", "Cleans out the cache and install paths."
    method_option "verbose"
    method_option "line-numbers"
    def clean
      environment.ensure!
      environment.clean!
    end

    desc "install", "Installs all of the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    method_option "clean"
    def install
      environment.ensure!
      environment.clean! if options["clean"]
      environment.install!
    end

    desc "resolve", "Resolves the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    method_option "clean"
    def resolve
      environment.ensure!
      environment.clean! if options["clean"]
      environment.resolve!
    end

    desc "update", "Updates the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    def update(*names)
      environment.ensure!
      if names.empty?
        environment.resolve!(:force => true)
      else
        environment.update!(names)
      end
    end

    desc "init", "Initializes the current directory."
    def init
      puts "Nothing to do."
    end

  private

    def environment
      root_module.environment
    end

  end
end
