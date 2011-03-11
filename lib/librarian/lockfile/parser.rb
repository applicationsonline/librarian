require 'librarian/helpers/debug'

require 'librarian/manifest'
require 'librarian/dependency'

module Librarian
  class Lockfile
    class Parser

      class Manifest < Manifest
        def initialize(source, name, version, dependencies)
          super(source, name)
          @_version = version
          @_dependencies = dependencies
        end
        def fetch_version!
          @_version
        end
        def fetch_dependencies!
          @_dependencies
        end
      end

      include Helpers::Debug

      attr_reader :root_module

      def initialize(root_module)
        @root_module = root_module
      end

      def parse(string)
        string = string.dup
        source_type_names_map = Hash[dsl_class.source_types.map{|t| [t[1].lock_name, t[1]]}]
        source_type_names = dsl_class.source_types.map{|t| t[1].lock_name}
        lines = string.split(/(\r?\n)+/).reject{|l| l =~ /^\s*$/}
        sources = []
        while source_type_names.include?(lines.first)
          source = {}
          source_type_name = lines.shift
          source[:type] = source_type_names_map[source_type_name]
          options = {}
          while lines.first =~ /^ {2}([\w-]+):\s+(.+)$/
            lines.shift
            options[$1.to_sym] = $2
          end
          source[:options] = options
          lines.shift # specs
          manifests = {}
          while lines.first =~ /^ {4}([\w-]+) \((.*)\)$/
            lines.shift
            name = $1
            manifests[name] = {:version => $2, :dependencies => {}}
            while lines.first =~ /^ {6}([\w-]+) \((.*)\)$/
              lines.shift
              manifests[name][:dependencies][$1] = $2.split(/,\s*/)
            end
          end
          source[:manifests] = manifests
          sources << source
        end
        compile(sources)
      end

    private

      def compile(sources_ast)
        manifests = {}
        sources_ast.each do |source_ast|
          source_type = source_ast[:type]
          source = source_type.from_lock_options(source_ast[:options])
          source_ast[:manifests].each do |manifest_name, manifest_ast|
            manifests[manifest_name] = Manifest.new(
              source,
              manifest_name,
              manifest_ast[:version],
              manifest_ast[:dependencies].map{|k, v| Dependency.new(k, v, nil)}
            )
          end
        end
        manifests = manifests.map do |name, manifest|
          Manifest.new(
            manifest.source,
            manifest.name,
            manifest.version,
            Hash[manifest.dependencies.map do |d| [d.name,
              Dependency.new(d.name, d.requirement, manifests[d.name].source)
            ]end]
          )
        end
        Resolver.new(root_module).sort(manifests)
      end

      def dsl_class
        root_module.dsl_class
      end

    end
  end
end
