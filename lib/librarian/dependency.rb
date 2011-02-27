require 'rubygems'

module Librarian
  class Dependency

    attr_reader :name, :requirement, :source

    def initialize(name, requirement, source)
      @name = name
      @requirement = Gem::Requirement.create(requirement)
      @source = source
    end

  end
end
