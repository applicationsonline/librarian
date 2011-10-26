require 'rubygems'

require 'librarian/helpers/debug'

module Librarian
  class Dependency

    class Requirement < Gem::Requirement
    end

    include Helpers::Debug

    attr_reader :name, :requirement, :source

    def initialize(name, requirement, source)
      @name = name
      @requirement = Requirement.create(requirement)
      @source = source
      @manifests = nil
    end

    def manifests
      @manifests ||= cache_manifests!
    end

    def cache_manifests!
      source.cache!([self])
      source.manifests(self)
    end

    def satisfied_by?(manifest)
      manifest.satisfies?(self)
    end

    def to_s
      "#{name} (#{requirement}) <#{source}>"
    end

    def ==(other)
      !other.nil? &&
      self.class        == other.class        &&
      self.name         == other.name         &&
      self.requirement  == other.requirement  &&
      self.source       == other.source
    end

  private

    def environment
      source.environment
    end

  end
end
