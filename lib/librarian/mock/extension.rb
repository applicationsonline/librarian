require 'librarian/mock/environment'

module Librarian
  module Mock
    extend self
    extend Librarian

    module Overrides
      def registry(options = nil, &block)
        environment.registry(options, &block)
      end
    end

    extend Overrides
  end
end
