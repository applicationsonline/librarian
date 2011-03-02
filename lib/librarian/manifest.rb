module Librarian
  class Manifest

    attr_reader :source, :name, :version, :dependencies

    def initialize(source, name, version = nil, dependencies = nil)
      @source = source
      @name = name
      @version = version && Gem::Version.new(version)
      @dependencies = dependencies && _normalize_dependencies(dependencies)
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
