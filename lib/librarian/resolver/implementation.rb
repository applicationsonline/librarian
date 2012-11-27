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

      def resolve(dependencies, manifests = {})
        dependencies += sourced_dependencies_for_manifests(manifests)
        recursive_resolve([], manifests, dependencies)
      end

    private

      def recursive_resolve(dependencies, manifests, queue)
        dependencies = dependencies.dup
        manifests = manifests.dup
        queue = queue.dup

        return nil if queue.any?{|d| m = manifests[d.name] ; m && !d.satisfied_by?(m)}
        queue.reject!{|d| manifests[d.name]}
        return manifests if queue.empty?

        debug_schedule queue if dependencies.empty?

        dependency = queue.shift
        dependencies << dependency
        related_dependencies = dependencies.select{|d| d.name == dependency.name}

        resolving_dependency_map_find_manifests(dependency) do |manifest|
          next if related_dependencies.any?{|d| !d.satisfied_by?(manifest)}

          m = manifests.merge(dependency.name => manifest)
          a = sourced_dependencies_for_manifest(manifest)
          debug_schedule a
          q = queue + a
          recursive_resolve(dependencies, m, q)
        end
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

      def debug_schedule(dependencies)
        dependencies.each do |d|
          debug { "Scheduling #{d}" }
        end
      end

      def map_find(enum)
        enum.each do |obj|
          res = yield(obj)
          res.nil? or return res
        end
        nil
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
