module Librarian
  class Specfile

    attr_reader :path, :dependencies

    def initialize(dsl_class, path)
      @path = path
      spec = dsl_class.run(self)
      @dependencies = spec.dependencies
    end

  end
end
