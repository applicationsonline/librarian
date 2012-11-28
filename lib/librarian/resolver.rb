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
      manifests = implementation.resolve(partial_manifests)
      if manifests
        enforce_consistency!(spec.dependencies, manifests)
        manifests = sort(manifests)
        Resolution.new(spec.dependencies, manifests)
      end
    end

  private

    def enforce_consistency!(dependencies, manifests)
      return if dependencies.all?{|d|
        m = manifests[d.name]
        m && d.satisfied_by?(m)
      } && ManifestSet.new(manifests).consistent?

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

    def sort(manifests)
      ManifestSet.sort(manifests)
    end

    def debug(*args, &block)
      environment.logger.debug(*args, &block)
    end

  end
end
