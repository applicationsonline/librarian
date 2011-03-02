require 'tsort'

require 'librarian/dependency'

module Librarian
  class Resolver

    class GraphHash < Hash
      include TSort
      alias tsort_each_node each_key
      def tsort_each_child(node, &block)
        self[node].each(&block)
      end
    end

    attr_reader :root_module, :source

    def initialize(root_module, source)
      @root_module = root_module
      @source = source
    end

    def resolve(dependencies)
      manifests = {}
      queue = dependencies.dup
      until queue.empty?
        dependency = queue.shift
        unless manifests.key?(dependency.name)
          debug { "Resolving #{dependency.name}" }
          dependency.source.cache!([dependency])
          manifest = dependency.source.manifests(dependency).first
          subdeps = manifest.
            dependencies.
            select{|d| !manifests.key?(d.name)}.
            map{|d| Dependency.new(d.name, d.requirement.as_list, source)}
          queue.concat(subdeps)
          manifests[dependency.name] = manifest
        end
      end
      manifest_pairs = GraphHash[manifests.map{|k, m| [k, m.dependencies.map{|d| d.name}]}]
      manifest_names = manifest_pairs.tsort
      manifest_names.map{|n| manifests[n]}
    end

  private

    def relative_path_to(path)
      root_module.project_relative_path_to(path)
    end

    def debug
      root_module.ui.debug "[Librarian] #{yield}"
    end

  end
end
