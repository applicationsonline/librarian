require "librarian/environment"
require "librarian/mock/dsl"
require "librarian/mock/version"

module Librarian
  module Mock
    class Environment < Environment

      def install_path
        nil
      end

      def registry(options = nil, &block)
        @registry ||= Source::Mock::Registry.new
        @registry.merge!(options, &block)
        @registry
      end

    end
  end
end
