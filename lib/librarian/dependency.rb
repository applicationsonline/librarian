require 'rubygems'

module Librarian
  class Dependency

    attr_reader :name, :requirement, :source

    def initialize(name, requirement, source)
      @name = name
      @requirement = Gem::Requirement.create(requirement)
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

  end
end
