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

      attr_accessor :resolver, :spec
      private :resolver=, :spec=

      def initialize(resolver, spec)
        self.resolver = resolver
        self.spec = spec
        @level = 0
      end

      def resolve(manifests)
        manifests = index_by(manifests, &:name) if manifests.kind_of?(Array)
        addtl = spec.dependencies + sourced_dependencies_for_manifests(manifests)
        recursive_resolve([], manifests, [], addtl)
      end

    private

      def find_inconsistency(dep, deps, mans)
        m = mans[dep.name]
        dep.satisfied_by?(m) or return m if m
        deps.find{|d| !dep.consistent_with?(d)}
      end

      def recursive_resolve(dependencies, manifests, queue, addtl)
        dependencies = dependencies.dup
        manifests = manifests.dup
        queue = queue.dup

        return unless enqueue_dependencies(queue, addtl, dependencies, manifests)
        return unless shift_resolved_enqueued_dependencies(dependencies, manifests, queue)
        return manifests if queue.empty?

        dependency = queue.shift
        dependencies << dependency
        all_deps = dependencies + queue

        resolving_dependency_map_find_manifests(dependency) do |manifest|
          next unless check_manifest(manifest, all_deps)

          m = manifests.merge(dependency.name => manifest)
          a = sourced_dependencies_for_manifest(manifest)

          recursive_resolve(dependencies, m, queue, a)
        end
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the enqueueables could all be enqueued.
      # Returns +false+ if there was an inconsistency when trying to enqueue one
      # or more of them.
      # This modifies +queue+ but does not modify any other arguments.
      def enqueue_dependencies(queue, enqueueables, dependencies, manifests)
        enqueueables.each do |d|
          if q = find_inconsistency(d, dependencies + queue, manifests)
            debug_conflict d, q
            return false
          end
          debug_schedule d
          queue << d
        end
        true
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the resolved enqueued dependencies at the front of the
      # queue could all be moved to the resolved dependencies list.
      # Returns +false+ if there was an inconsistency when trying to move one or
      # more of them.
      # This modifies +queue+ and +dependencies+.
      def shift_resolved_enqueued_dependencies(dependencies, manifests, queue)
        all_deps = dependencies + queue
        while (dependency = queue.first) && manifests[dependency.name]
          if q = find_inconsistency(dependency, all_deps, manifests)
            debug_conflict dependency, q
            return false
          end
          dependencies << queue.shift
        end
        true
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the manifest satisfies all of the dependencies.
      # Returns +false+ if there was a dependency that the manifest does not
      # satisfy.
      def check_manifest(manifest, all_deps)
        related = all_deps.select{|d| d.name == manifest.name}
        if q = related.find{|d| !d.satisfied_by?(manifest)}
          debug_conflict manifest, q
          return false
        end
        true
      end

      def default_source
        @default_source ||= MultiSource.new(spec.sources)
      end

      def dependency_source_map
        @dependency_source_map ||=
          Hash[spec.dependencies.map{|d| [d.name, d.source]}]
      end

      def sourced_dependency_for(dependency)
        return dependency if dependency.source

        source = dependency_source_map[dependency.name] || default_source
        Dependency.new(dependency.name, dependency.requirement, source)
      end

      def sourced_dependencies_for_manifest(manifest)
        manifest.dependencies.map{|d| sourced_dependency_for(d)}
      end

      def sourced_dependencies_for_manifests(manifests)
        manifests = manifests.values if manifests.kind_of?(Hash)
        manifests.map{|m| sourced_dependencies_for_manifest(m)}.flatten(1)
      end

      def resolving_dependency_map_find_manifests(dependency)
        scope_resolving_dependency dependency do
          map_find(dependency.manifests) do |manifest|
            scope_checking_manifest dependency, manifest do
              yield manifest
            end
          end
        end
      end

      def scope_resolving_dependency(dependency)
        debug { "Resolving #{dependency}" }
        resolution = nil
        scope do
          scope_checking_manifests do
            resolution = yield
          end
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

      def debug_schedule(dependency)
        debug { "Scheduling #{dependency}" }
      end

      def debug_conflict(dependency, conflict)
        debug { "Conflict between #{dependency} and #{conflict}" }
      end

      def map_find(enum)
        enum.each do |obj|
          res = yield(obj)
          res.nil? or return res
        end
        nil
      end

      def index_by(enum)
        Hash[enum.map{|obj| [yield(obj), obj]}]
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
