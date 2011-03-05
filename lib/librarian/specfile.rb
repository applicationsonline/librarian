module Librarian
  class Specfile

    attr_reader :path, :dependencies, :source

    def initialize(dsl_class, path)
      @path = path
      spec = dsl_class.run(self)
      @dependencies = spec.dependencies
      @source = spec.source
    end

  end
end
