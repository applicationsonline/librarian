require 'rubygems'

module Librarian
  class Dependency

    attr_reader :name, :requirements, :source

    def initialize(name, requirements, source)
      @name = name
      @requirements = Gem::Requirement.create(requirements)
      @source = source
    end

  end
end
