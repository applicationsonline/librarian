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
    end

    extend Overrides
  end
end
