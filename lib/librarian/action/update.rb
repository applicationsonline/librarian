require "librarian/manifest_set"
require "librarian/resolver"
require "librarian/spec_change_set"
require "librarian/action/base"
require "librarian/action/persist_resolution_mixin"

module Librarian
  module Action
    class Update < Base
      include PersistResolutionMixin

      def run
        unless lockfile_path.exist?
          raise Error, "Lockfile missing!"
        end
        previous_resolution = lockfile.load(lockfile_path.read)
        spec = specfile.read(previous_resolution.sources)
        changes = spec_change_set(spec, previous_resolution)
        manifests = changes.same? ? previous_resolution.manifests : changes.analyze
        partial_manifests = ManifestSet.deep_strip(manifests, dependency_names)
        unpinnable_sources = previous_resolution.sources - partial_manifests.map(&:source)
        unpinnable_sources.each(&:unpin!)

        resolution = resolver.resolve(spec, partial_manifests)
        persist_resolution(resolution)
      end

    private

      def dependency_names
        options[:names]
      end

      def resolver
        Resolver.new(environment)
      end

      def spec_change_set(spec, lock)
        SpecChangeSet.new(environment, spec, lock)
      end

    end
  end
end
