module Librarian
  class Specfile

    attr_reader :path, :dependencies

    def initialize(dsl_class, path)
      @path = path
      dsl_target = dsl_class.run(self)
      @dependencies = dsl_target.dependencies
    end

  end
end
