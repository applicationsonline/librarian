module Librarian
  class Spec

    attr_accessor :sources, :dependencies
    private :sources=, :dependencies=

    def initialize(sources, dependencies)
      self.sources = sources
      self.dependencies = dependencies
    end

  end
end
