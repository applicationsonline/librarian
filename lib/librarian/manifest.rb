module Librarian
  class Manifest

    attr_reader :name, :version, :dependencies

    def initialize(name, version, dependencies)
      @name = name
      @version = Gem::Version.new(version)
      @dependencies = _normalize_dependencies(dependencies)
    end

  private

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
