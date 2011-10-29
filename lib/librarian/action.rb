require "librarian/helpers/debug"

module Librarian
  class Action

    include Helpers::Debug

    attr_accessor :environment
    private :environment=

    def initialize(environment)
      self.environment = environment
    end

  end
end
