require 'librarian/specfile/dsl'

module Librarian
  class Specfile

    attr_reader :path, :dependencies

    def initialize(path)
      @path = path
      dsl_target = Dsl.run(self)
      @dependencies = dsl_target.dependencies
    end

  end
end
