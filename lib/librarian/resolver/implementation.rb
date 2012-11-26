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
          sources.reverse.map{|source| source.manifests(name)}.flatten(1).compact
        end
        def to_s
          "(no source specified)"
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
        @default_source ||= MultiSource.new(spec.sources)
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

        return nil if queue.any?{|d| m = manifests[d.name] ; m && !d.satisfied_by?(m)}
        queue.reject!{|d| manifests[d.name]}
        return [dependencies, manifests, queue] if queue.empty?

        debug_schedule queue if dependencies.empty?

        dependency = queue.shift
        dependencies << dependency
        related_dependencies = dependencies.select{|d| d.name == dependency.name}

        scope_resolving_dependency dependency do
          scope_checking_manifests do
            resolution = nil
            dependency.manifests.each do |manifest|
              break if resolution

              scope_checking_manifest dependency, manifest do
                if related_dependencies.all?{|d| d.satisfied_by?(manifest)}
                  m = manifests.merge(dependency.name => manifest)
                  a = manifest.dependencies.map{|d| sourced_dependency_for(d)}
                  debug_schedule a
                  q = queue + a
                  resolution = recursive_resolve(dependencies.dup, m, q)
                end
              end
            end
            resolution
          end
        end
      end

    private

      def scope_resolving_dependency(dependency)
        debug { "Resolving #{dependency}" }
        resolution = nil
        scope do
          resolution = yield
          if resolution
            debug { "Resolved #{dependency}" }
          else
            debug { "Failed to resolve #{dependency}" }
          end
        end
        resolution
      end

      def scope_checking_manifests
        debug { "Checking manifests" }
        scope do
          yield
        end
      end

      def scope_checking_manifest(dependency, manifest)
        debug { "Checking #{manifest}" }
        resolution = nil
        scope do
          resolution = yield
          if resolution
            debug { "Resolved #{dependency} at #{manifest}" }
          else
            debug { "Backtracking from #{manifest}" }
          end
        end
        resolution
      end

      def debug_schedule(dependencies)
        dependencies.each do |d|
          debug { "Scheduling #{d}" }
        end
      end

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
