require 'librarian/specfile'
require 'librarian/mock/dsl'

module Librarian
  module Mock
    extend self
    extend Librarian

    module Overrides
      def specfile_name
        'Mockfile'
      end

      def install_path
        nil
      end

      def dsl_class
        Dsl
      end

      def registry(options = nil, &block)
        registry = Source::Mock::Registry
        registry.clear! if options && options[:clear]
        registry.merge!(&block) if block
        registry
      end
    end

    extend Overrides
  end
end
