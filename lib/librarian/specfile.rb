module Librarian
  class Specfile

    attr_reader :dsl_class, :path, :dependencies, :source

    def initialize(dsl_class, path)
      @dsl_class = dsl_class
      @path = path
    end

    def read
      dsl_class.run(self)
    end

  end
end
