require 'rubygems'

require 'librarian/helpers/debug'
require 'librarian/support/abstract_method'

module Librarian
  class Manifest

    class Version < Gem::Version
    end

    include Support::AbstractMethod
    include Helpers::Debug

    attr_accessor :source, :name
    private :source=, :name=

    abstract_method :fetch_version!, :fetch_dependencies!
    abstract_method :install!

    def initialize(source, name)
      assert_name_valid! name

      self.source = source
      self.name = name

      @fetched_version = nil
      @defined_version = nil
      @fetched_dependencies = nil
      @defined_dependencies = nil
    end

    def to_s
      "#{name}/#{version} <#{source}>"
    end

    def version
      @defined_version || @fetched_version ||= _normalize_version(fetch_version!)
    end

    def version=(version)
      @defined_version = _normalize_version(version)
    end

    def version?
      if @defined_version
        @fetched_version ||= _normalize_version(fetch_version!)
        @defined_version == @fetched_version
      end
    end

    def dependencies
      @defined_dependencies || @fetched_dependencies ||= _normalize_dependencies(fetch_dependencies!)
    end

    def dependencies=(dependencies)
      @defined_dependencies = _normalize_dependencies(dependencies)
    end

    def dependencies?
      if @defined_dependencies
        @fetched_dependencies ||= _normalize_dependencies(fetch_dependencies!)
        @defined_dependencies.zip(@fetched_dependencies).all? do |pair|
          a, b = *pair
          a.name == b.name && a.requirement == b.requirement
        end
      end
    end

    def satisfies?(dependency)
      dependency.requirement.satisfied_by?(version)
    end

  private

    def environment
      source.environment
    end

    def _normalize_version(version)
      Version.new(version)
    end

    def _normalize_dependencies(dependencies)
      if Hash === dependencies
        dependencies = dependencies.map{|k, v| Dependency.new(k, v, nil)}
      end
      dependencies.sort_by{|d| d.name}
    end

    def assert_name_valid!(name)
      raise ArgumentError, "name (#{name.inspect}) must be sensible" unless name =~ /^\S.*\S$/
    end

  end
end
