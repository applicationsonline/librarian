require "librarian/environment"
require "librarian/mock/dsl"

module Librarian
  module Mock
    class Environment < Environment

      def specfile_name
        "Mockfile"
      end

      def install_path
        nil
      end

      def registry(options = nil, &block)
        registry = Source::Mock::Registry
        registry.clear! if options && options[:clear]
        registry.merge!(&block) if block
        registry
      end
    end

  end
end
