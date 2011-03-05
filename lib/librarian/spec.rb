module Librarian
  class Spec

    attr_reader :source, :dependencies

    def initialize(source, dependencies)
      @source, @dependencies = source, dependencies
    end

  end
end
