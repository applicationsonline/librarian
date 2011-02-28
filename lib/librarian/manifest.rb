module Librarian
  class Manifest

    attr_reader :name, :version, :dependencies

    def initialize(name, version, dependencies)
      @name = name
      @version = version
      @dependencies = dependencies
    end

  end
end
