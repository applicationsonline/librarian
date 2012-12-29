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
        assert_no_manifests_missing!(names)

        present_each(names, :detailed => full)
      end

      def present_one(manifest, options = { })
        full = options[:detailed]

        say "#{manifest.name} (#{manifest.version})" do
          full or next

          present_one_source(manifest)
          present_one_dependencies(manifest)
        end
      end

      private

      def present_each(names, options)
        names.each do |name|
          manifest = manifest(name)
          present_one(manifest, options)
        end
      end

      def present_one_source(manifest)
        say "source: #{manifest.source}"
      end

      def present_one_dependencies(manifest)
        manifest.dependencies.empty? and return

        say "dependencies:" do
          deps = manifest.dependencies.sort_by(&:name)
          deps.each do |dependency|
            say "#{dependency.name} (#{dependency.requirement})"
          end
        end
      end

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

      def assert_no_manifests_missing!(names)
        missing_names = names.reject{|name| manifest(name)}
        unless missing_names.empty?
          raise Error, "not found: #{missing_names.map(&:inspect).join(', ')}"
        end
      end

    end
  end
end
