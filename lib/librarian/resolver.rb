require 'tsort'

require 'librarian/helpers/debug'

require 'librarian/dependency'
require 'librarian/resolution'

module Librarian
  class Resolver

    class GraphHash < Hash
      include TSort
      alias tsort_each_node each_key
      def tsort_each_child(node, &block)
        self[node].each(&block)
      end
    end

    class Implementation
      include Helpers::Debug

      attr_reader :resolver, :source, :dependency_source_map

      def initialize(resolver, spec)
        @resolver = resolver
        @source = spec.source
        @dependency_source_map = Hash[spec.dependencies.map{|d| [d.name, d.source]}]
        @level = 0
      end

      def resolve(dependencies, manifests = {})
        resolution = recursive_resolve([], manifests, dependencies.dup)
        resolution ? resolution[1] : nil
      end

      def recursive_resolve(dependencies, manifests, queue)
        if dependencies.empty?
          queue.each do |dependency|
            debug { "Scheduling #{dependency}" }
          end
        end
        failure = false
        until failure || queue.empty?
          dependency = queue.shift
          dependencies << dependency
          debug { "Resolving #{dependency}" }
          scope do
            if manifests.key?(dependency.name)
              unless dependency.satisfied_by?(manifests[dependency.name])
                debug { "Conflicts with #{manifests[dependency.name]}" }
                failure = true
              else
                debug { "Accords with all prior constraints" }
                # nothing left to do
              end
            else
              debug { "No known prior constraints" }
              resolution = nil
              related_dependencies = dependencies.select{|d| d.name == dependency.name}
              unless dependency.manifests && dependency.manifests.first
                debug { "No known manifests" }
              else
                debug { "Checking manifests" }
                scope do
                  dependency.manifests.each do |manifest|
                    unless resolution
                      debug { "Checking #{manifest}" }
                      scope do
                        if related_dependencies.all?{|d| d.satisfied_by?(manifest)}
                          m = manifests.merge(dependency.name => manifest)
                          a = manifest.dependencies.map { |d|
                            d.source ? d :
                            !dependency_source_map.key?(d.name) ?
                            Dependency.new(d.name, d.requirement, source) :
                            Dependency.new(d.name, d.requirement, dependency_source_map[d.name])
                          }
                          a.each do |d|
                            debug { "Scheduling #{d}" }
                          end
                          q = queue + a
                          resolution = recursive_resolve(dependencies.dup, m, q)
                        end
                        if resolution
                          debug { "Resolved #{dependency} at #{manifest}" }
                        else
                          debug { "Backtracking from #{manifest}" }
                        end
                      end
                    end
                  end
                end
                if resolution
                  debug { "Resolved #{dependency}" }
                else
                  debug { "Failed to resolve #{dependency}" }
                end
              end
              unless resolution
                failure = true
              else
                dependencies, manifests, queue = *resolution
              end
            end
          end
        end
        failure ? nil : [dependencies, manifests, queue]
      end

    private

      def scope
        @level += 1
        yield
      ensure
        @level -= 1
      end

      def debug
        super { '  ' * @level + yield }
      end

      def root_module
        resolver.root_module
      end
    end

    include Helpers::Debug

    attr_reader :root_module

    def initialize(root_module)
      @root_module = root_module
    end

    def resolve(spec, partial_manifests = [])
      implementation = Implementation.new(self, spec)
      partial_manifests_index = Hash[partial_manifests.map{|m| [m.name, m]}]
      manifests = implementation.resolve(spec.dependencies, partial_manifests_index)
      manifests = sort(manifests) if manifests
      Resolution.new(spec.dependencies, manifests)
    end

    def sort(manifests)
      manifests = Hash[manifests.map{|m| [m.name, m]}] if Array === manifests
      manifest_pairs = GraphHash[manifests.map{|k, m| [k, m.dependencies.map{|d| d.name}]}]
      manifest_names = manifest_pairs.tsort
      manifest_names.map{|n| manifests[n]}
    end

  end
end
