require 'librarian/support/abstract_method'

module Librarian
  class Manifest

    include Support::AbstractMethod

    attr_reader :source, :name

    abstract_method :cache_version!, :cache_dependencies!

    def initialize(source, name)
      @source = source
      @name = name
      @version = nil
      @dependencies = nil
    end

    def version
      @version ||= _normalize_version(cache_version!)
    end

    def dependencies
      @dependencies ||= _normalize_dependencies(cache_dependencies!)
    end

  private

    def _normalize_version(version)
      Gem::Version.new(version)
    end

    def _normalize_dependencies(dependencies)
      case dependencies
      when Hash
        dependencies.map{|k, v| Dependency.new(k, v, nil)}
      else
        dependencies
      end
    end

  end
end
