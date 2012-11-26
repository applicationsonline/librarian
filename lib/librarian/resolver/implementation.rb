require 'librarian/dependency'

module Librarian
  class Resolver
    class Implementation

      class MultiSource
        attr_accessor :sources
        def initialize(sources)
          self.sources = sources
        end
        def manifests(name)
          sources.reverse.map{|source| source.manifests(name)}.flatten(1)
        end
      end

      attr_accessor :resolver, :spec, :dependency_source_map
      private :resolver=, :spec=, :dependency_source_map=

      def initialize(resolver, spec)
        self.resolver = resolver
        self.spec = spec
        self.dependency_source_map = Hash[spec.dependencies.map{|d| [d.name, d.source]}]
        @level = 0
      end

      def resolve(dependencies, manifests = {})
        dependencies += manifests.values.map { |m|
          m.dependencies.map { |d| sourced_dependency_for(d) }
        }.flatten(1)
        resolution = recursive_resolve([], manifests, dependencies)
        resolution ? resolution[1] : nil
      end

      def default_source
        MultiSource.new(spec.sources)
      end

      def sourced_dependency_for(dependency)
        return dependency if dependency.source

        source = dependency_source_map[dependency.name] || default_source
        Dependency.new(dependency.name, dependency.requirement, source)
      end

      def recursive_resolve(dependencies, manifests, queue)
        dependencies = dependencies.dup
        manifests = manifests.dup
        queue = queue.dup

        if dependencies.empty?
          queue.each do |dependency|
            debug { "Scheduling #{dependency}" }
          end
        end

        return nil if queue.any?{|d| m = manifests[d.name] ; m && !d.satisfied_by?(m)}
        queue.reject!{|d| manifests[d.name]}
        return [dependencies, manifests, queue] if queue.empty?

        dependency = queue.shift
        dependencies << dependency
        debug { "Resolving #{dependency}" }
        resolution = nil
        scope do
          related_dependencies = dependencies.select{|d| d.name == dependency.name}
          unless dependency.manifests && dependency.manifests.first
            debug { "No known manifests" }
          else
            debug { "Checking manifests" }
            scope do
              dependency.manifests.each do |manifest|
                break if resolution

                debug { "Checking #{manifest}" }
                scope do
                  if related_dependencies.all?{|d| d.satisfied_by?(manifest)}
                    m = manifests.merge(dependency.name => manifest)
                    a = manifest.dependencies.map { |d| sourced_dependency_for(d) }
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
            if resolution
              debug { "Resolved #{dependency}" }
            else
              debug { "Failed to resolve #{dependency}" }
            end
          end
        end
        resolution
      end

    private

      def scope
        @level += 1
        yield
      ensure
        @level -= 1
      end

      def debug
        environment.logger.debug { '  ' * @level + yield }
      end

      def environment
        resolver.environment
      end

    end
  end
end
