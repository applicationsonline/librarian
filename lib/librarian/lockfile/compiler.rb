require 'librarian/helpers/debug'

module Librarian
  class Lockfile
    class Compiler

      include Helpers::Debug

      attr_reader :root_module

      def initialize(root_module)
        @root_module = root_module
      end

      def compile(manifests)
        out = []
        dsl_class.source_types.map{|t| t[1]}.each do |type|
          type_manifests = manifests.select{|m| type === m.source}
          sources = type_manifests.map{|m| m.source}.uniq
          sources.each do |source|
            source_manifests = type_manifests.select{|m| source == m.source}
            save_source(source, source_manifests) { |s| out << "#{s}\n" }
          end
        end
        out.join
      end

    private

      def save_source(source, manifests)
        yield "#{source.class.lock_name}"
        options = source.class.to_lock_options(source)
        remote = options.delete(:remote)
        yield "  remote: #{remote}"
        options.to_a.sort{|a, b| a[0] <=> b[0]}.each do |o|
          yield "  #{o[0]}: #{o[1]}"
        end
        yield "  specs:"
        manifests.sort{|a, b| a.name <=> b.name}.each do |manifest|
          yield "    #{manifest.name} (#{manifest.version})"
          manifest.dependencies.sort{|a, b| a.name <=> b.name}.each do |dependency|
            yield "      #{dependency.name} (#{dependency.requirement})"
          end
        end
        yield ""
      end

      def dsl_class
        root_module.dsl_class
      end

    end
  end
end
