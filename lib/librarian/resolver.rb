require 'librarian/resolver/implementation'
require 'librarian/manifest_set'
require 'librarian/resolution'

module Librarian
  class Resolver

    attr_accessor :environment
    private :environment=

    def initialize(environment)
      self.environment = environment
    end

    def resolve(spec, partial_manifests = [])
      implementation = Implementation.new(self, spec)
      partial_manifests_index = Hash[partial_manifests.map{|m| [m.name, m]}]
      manifests = implementation.resolve(spec.dependencies, partial_manifests_index)
      manifests = sort(manifests) if manifests
      Resolution.new(spec.dependencies, manifests)
    end

    def sort(manifests)
      ManifestSet.sort(manifests)
    end

  end
end
