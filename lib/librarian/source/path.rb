require 'librarian/particularity'
require 'librarian/source/local'

module Librarian
  module Source
    class Path

      include Particularity
      include Local

      attr_reader :path

      def initialize(path, options)
        @path = Pathname.new(path).expand_path(root_module.project_path)
      end

      def to_s
        path
      end

      def cache!(dependencies)
      end

    end
  end
end
