require 'librarian/particularity'
require 'librarian/source/local'

module Librarian
  module Source
    class Path

      include Particularity
      include Local

      class << self
        LOCK_NAME = 'PATH'
        def lock_name
          LOCK_NAME
        end
        def from_lock_options(options)
          new(options[:remote], options.reject{|k| k == :remote})
        end
        def to_lock_options(source)
          {:remote => source.path}
        end
      end

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
