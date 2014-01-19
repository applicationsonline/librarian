require 'librarian/error'
require 'librarian/resolver/implementation'
require 'librarian/manifest_set'
require 'librarian/resolution'

module Librarian
  class Resolver

    attr_accessor :environment, :cyclic
    private :environment=, :cyclic=

    # Options:
    #   cyclic: truthy if the resolver should permit cyclic resolutions
    def initialize(environment, options = { })
      unrecognized_options = options.keys - [:cyclic]
      unrecognized_options.empty? or raise Error,
        "unrecognized options: #{unrecognized_options.join(", ")}"
      self.environment = environment
      self.cyclic = !!options[:cyclic]
    end

    def resolve(spec, partial_manifests = [])
      manifests = implementation(spec).resolve(partial_manifests)
      manifests or return
      enforce_consistency!(spec.dependencies, manifests)
      enforce_acyclicity!(manifests) unless cyclic
      manifests = sort(manifests)
      Resolution.new(spec.dependencies, manifests)
    end

  private

    def implementation(spec)
      Implementation.new(self, spec, :cyclic => cyclic)
    end

    def enforce_consistency!(dependencies, manifests)
      manifest_set = ManifestSet.new(manifests)
      return if manifest_set.in_compliance_with?(dependencies)
      return if manifest_set.consistent?

      debug { "Resolver Malfunctioned!" }
      errors = []
      dependencies.sort_by(&:name).each do |d|
        m = manifests[d.name]
        if !m
          errors << ["Depends on #{d}", "Missing!"]
        elsif !d.satisfied_by?(m)
          errors << ["Depends on #{d}", "Found: #{m}"]
        end
      end
      unless errors.empty?
        errors.each do |a, b|
          debug { "  #{a}" }
          debug { "    #{b}" }
        end
      end
      manifests.values.sort_by(&:name).each do |manifest|
        errors = []
        manifest.dependencies.sort_by(&:name).each do |d|
          m = manifests[d.name]
          if !m
            errors << ["Depends on: #{d}", "Missing!"]
          elsif !d.satisfied_by?(m)
            errors << ["Depends on: #{d}", "Found: #{m}"]
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

    def enforce_acyclicity!(manifests)
      ManifestSet.cyclic?(manifests) or return
      debug { "Resolver Malfunctioned!" }
      raise Error, "Resolver Malfunctioned!"
    end

    def sort(manifests)
      ManifestSet.sort(manifests)
    end

    def debug(*args, &block)
      environment.logger.debug(*args, &block)
    end

  end
end
