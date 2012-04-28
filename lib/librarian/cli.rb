require 'thor'
require 'thor/actions'

require 'librarian'
require 'librarian/error'
require 'librarian/action'
require "librarian/ui"

module Librarian
  class Cli < Thor

    autoload :ManifestPresenter, "librarian/cli/manifest_presenter"

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
      ensure!
      clean!
    end

    desc "install", "Resolves and installs all of the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    method_option "clean"
    def install
      ensure!
      clean! if options["clean"]
      resolve!
      install!
    end

    desc "update", "Updates and installs the dependencies you specify."
    method_option "verbose"
    method_option "line-numbers"
    def update(*names)
      ensure!
      if names.empty?
        resolve!(:force => true)
      else
        update!(:names => names)
      end
      install!
    end

    desc "outdated", "Lists outdated dependencies."
    method_option "verbose"
    method_option "line-numbers"
    def outdated
      ensure!
      resolution = environment.lock
      resolution.manifests.sort_by(&:name).each do |manifest|
        source = manifest.source
        source.cache!([manifest])
        source_manifest = source.manifests(manifest).first
        next if manifest.version == source_manifest.version
        say "#{manifest.name} (#{manifest.version} -> #{source_manifest.version})"
      end
    end

    desc "show", "Shows dependencies"
    method_option "verbose"
    method_option "line-numbers"
    method_option "detailed", :type => :boolean
    def show(*names)
      ensure!
      manifest_presenter.present(names, :detailed => options["detailed"])
    end

    desc "init", "Initializes the current directory."
    def init
      puts "Nothing to do."
    end

  private

    def environment
      root_module.environment
    end

    def ensure!(options = { })
      Action::Ensure.new(environment, options).run
    end

    def clean!(options = { })
      Action::Clean.new(environment, options).run
    end

    def install!(options = { })
      Action::Install.new(environment, options).run
    end

    def resolve!(options = { })
      Action::Resolve.new(environment, options).run
    end

    def update!(options = { })
      Action::Update.new(environment, options).run
    end

    def manifest_presenter
      ManifestPresenter.new(self, environment.lock.manifests)
    end

  end
end
