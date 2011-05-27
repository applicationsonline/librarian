require 'librarian/helpers/debug'

module Librarian
  class Lockfile
    class Compiler

      include Helpers::Debug

      attr_reader :root_module

      def initialize(root_module)
        @root_module = root_module
      end

      def compile(resolution)
        out = StringIO.new
        save_manifests(out, resolution.manifests)
        save_dependencies(out, resolution.dependencies)
        out.rewind
        out.read
      end

    private

      def save_manifests(out, manifests)
        dsl_class.source_types.map{|t| t[1]}.each do |type|
          type_manifests = manifests.select{|m| type === m.source}
          sources = type_manifests.map{|m| m.source}.uniq.sort_by{|s| s.to_s}
          sources.each do |source|
            source_manifests = type_manifests.select{|m| source == m.source}
            save_source(out, source, source_manifests)
          end
        end
      end

      def save_source(out, source, manifests)
        out.puts "#{source.class.lock_name}"
        options = source.to_lock_options
        remote = options.delete(:remote)
        out.puts "  remote: #{remote}"
        options.to_a.sort_by{|a| a[0].to_s}.each do |o|
          out.puts "  #{o[0]}: #{o[1]}"
        end
        out.puts "  specs:"
        manifests.sort_by{|a| a.name}.each do |manifest|
          out.puts "    #{manifest.name} (#{manifest.version})"
          manifest.dependencies.sort_by{|a| a.name}.each do |dependency|
            out.puts "      #{dependency.name} (#{dependency.requirement})"
          end
        end
        out.puts ""
      end

      def save_dependencies(out, dependencies)
        out.puts "DEPENDENCIES"
        dependencies.sort_by{|a| a.name}.each do |d|
          res = "#{d.name}"
          res << " (#{d.requirement})" if d.requirement
          out.puts "  #{res}"
        end
        out.puts ""
      end

      def dsl_class
        root_module.dsl_class
      end

    end
  end
end
