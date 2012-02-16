require 'rubygems'

require 'librarian/helpers/debug'

module Librarian
  class Dependency

    class Requirement < Gem::Requirement
    end

    include Helpers::Debug

    attr_accessor :name, :requirement, :source
    private :name=, :requirement=, :source=

    def initialize(name, requirement, source)
      assert_name_valid! name

      self.name = name
      self.requirement = Requirement.create(requirement)
      self.source = source

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

    def assert_name_valid!(name)
      raise ArgumentError, "name (#{name.inspect}) must be sensible" unless name =~ /^\S.*\S$/
    end

  end
end
