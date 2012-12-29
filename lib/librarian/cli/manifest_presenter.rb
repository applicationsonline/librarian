module Librarian
  class Cli
    class ManifestPresenter

      attr_accessor :cli, :manifests
      private :cli=, :manifests=

      def initialize(cli, manifests)
        self.cli = cli or raise ArgumentError, "cli required"
        self.manifests = manifests or raise ArgumentError, "manifests required"
        self.manifests_index = Hash[manifests.map{|m| [m.name, m]}]

        self.scope_level = 0
      end

      def present(names = [], options = { })
        full = options[:detailed]
        full = !names.empty? if full.nil?

        names = manifests.map(&:name).sort if names.empty?

        missing_names = names.reject{|name| manifest(name)}
        unless missing_names.empty?
          raise Error, "not found: #{missing_names.map(&:inspect).join(', ')}"
        end

        names.each do |name|
          manifest = manifest(name)
          present_one(manifest, :detailed => full)
        end
      end

      def present_one(manifest, options = { })
        full = options[:detailed]

        say "#{manifest.name} (#{manifest.version})" do
          full or next

          say "source: #{manifest.source}"

          manifest.dependencies.empty? and next
          say "dependencies:" do
            deps = manifest.dependencies.sort_by(&:name)
            deps.each do |dependency|
              say "#{dependency.name} (#{dependency.requirement})"
            end
          end
        end
      end

      private

      attr_accessor :scope_level, :manifests_index

      def manifest(name)
        manifests_index[name]
      end

      def say(string)
        cli.say "  " * scope_level << string
        if block_given?
          scope do
            yield
          end
        end
      end

      def scope
        original_scope_level = scope_level
        self.scope_level = scope_level + 1
        yield
      ensure
        self.scope_level = original_scope_level
      end

    end
  end
end
