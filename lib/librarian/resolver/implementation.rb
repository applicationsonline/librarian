require 'set'

require 'librarian/algorithms'
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

      class State
        attr_accessor :manifests, :dependencies, :queue
        private :manifests=, :dependencies=, :queue=
        def initialize(manifests, dependencies, queue)
          self.manifests = manifests
          self.dependencies = dependencies # resolved
          self.queue = queue # scheduled
        end
      end

      attr_accessor :resolver, :spec, :cyclic
      private :resolver=, :spec=, :cyclic=

      def initialize(resolver, spec, options = { })
        unrecognized_options = options.keys - [:cyclic]
        unrecognized_options.empty? or raise Error,
          "unrecognized options: #{unrecognized_options.join(", ")}"
        self.resolver = resolver
        self.spec = spec
        self.cyclic = !!options[:cyclic]
        @level = 0
      end

      def resolve(manifests)
        manifests = index_by(manifests, &:name) if manifests.kind_of?(Array)
        queue = spec.dependencies + sourced_dependencies_for_manifests(manifests)
        state = State.new(manifests.dup, [], queue)
        recursive_resolve(state)
      end

    private

      def recursive_resolve(state)
        shift_resolved_enqueued_dependencies(state) or return
        state.queue.empty? and return state.manifests

        state.dependencies << state.queue.shift
        dependency = state.dependencies.last

        resolving_dependency_map_find_manifests(dependency) do |manifest|
          check_manifest(state, manifest) or next
          check_manifest_for_cycles(state, manifest) or next unless cyclic

          m = state.manifests.merge(dependency.name => manifest)
          a = sourced_dependencies_for_manifest(manifest)
          s = State.new(m, state.dependencies.dup, state.queue + a)

          recursive_resolve(s)
        end
      end

      def find_inconsistency(state, dependency)
        m = state.manifests[dependency.name]
        dependency.satisfied_by?(m) or return m if m
        violation = lambda{|d| !dependency.consistent_with?(d)}
        state.dependencies.find(&violation) || state.queue.find(&violation)
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the resolved enqueued dependencies at the front of the
      # queue could all be moved to the resolved dependencies list.
      # Returns +false+ if there was an inconsistency when trying to move one or
      # more of them.
      # This modifies +queue+ and +dependencies+.
      def shift_resolved_enqueued_dependencies(state)
        while (d = state.queue.first) && state.manifests[d.name]
          if q = find_inconsistency(state, d)
            debug_conflict d, q
            return false
          end
          state.dependencies << state.queue.shift
        end
        true
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the manifest satisfies all of the dependencies.
      # Returns +false+ if there was a dependency that the manifest does not
      # satisfy.
      def check_manifest(state, manifest)
        violation = lambda{|d| d.name == manifest.name && !d.satisfied_by?(manifest)}
        if q = state.dependencies.find(&violation) || state.queue.find(&violation)
          debug_conflict manifest, q
          return false
        end
        true
      end

      # When using this method, you are required to check the return value.
      # Returns +true+ if the manifest does not introduce a cycle.
      # Returns +false+ if the manifest introduces a cycle.
      def check_manifest_for_cycles(state, manifest)
        manifests = state.manifests.merge(manifest.name => manifest)
        known = manifests.keys
        graph = Hash[manifests.map{|n, m| [n, m.dependencies.map(&:name) & known]}]
        if Algorithms::AdjacencyListDirectedGraph.cyclic?(graph)
          debug_cycle manifest
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

      def debug_cycle(manifest)
        debug { "Cycle with #{manifest}" }
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
