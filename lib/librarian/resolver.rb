require 'librarian/resolver/implementation'
require 'librarian/manifest_set'
require 'librarian/resolution'

module Librarian
  class Resolver
    include Helpers::Debug

    attr_accessor :environment
    private :environment=

    def initialize(environment)
      self.environment = environment
    end

    def resolve(spec, partial_manifests = [])
      implementation = Implementation.new(self, spec)
      partial_manifests_index = Hash[partial_manifests.map{|m| [m.name, m]}]
      manifests = implementation.resolve(spec.dependencies, partial_manifests_index)
      enforce_consistency!(manifests) if manifests
      manifests = sort(manifests) if manifests
      Resolution.new(spec.dependencies, manifests)
    end

    def enforce_consistency!(manifests)
      return if ManifestSet.new(manifests).consistent?

      debug { "Resolver Malfunctioned!" }
      manifests.values.sort_by(&:name).each do |manifest|
        errors = []
        manifest.dependencies.sort_by(&:name).each do |d|
          if !manifests[d]
            errors << ["Depends on: #{d}", "Missing!"]
          elsif !manifests[d].satisfies?(d)
            errors << ["Depends on: #{d}", "Found: #{manifests[d]}"]
          end
        end
        unless errors.empty?
          debug { "  #{manifest}" }
          errors.each do |a, b|
            debug { "    #{a}" }
            debug { "      #{b}" }
          end
        end
      end
      raise Error, "Resolver Malfunctioned!"
    end

    def sort(manifests)
      ManifestSet.sort(manifests)
    end

  end
end
