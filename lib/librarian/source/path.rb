require 'librarian/source/basic_api'
require 'librarian/source/local'

module Librarian
  module Source
    class Path
      include BasicApi
      include Local

      lock_name 'PATH'
      spec_options []

      attr_accessor :environment
      private :environment=
      attr_reader :path

      def initialize(environment, path, options)
        self.environment = environment
        @path = path
      end

      def to_s
        path.to_s
      end

      def ==(other)
        other &&
        self.class  == other.class &&
        self.path   == other.path
      end

      def to_spec_args
        [path.to_s, {}]
      end

      def to_lock_options
        {:remote => path}
      end

      def pinned?
        false
      end

      def unpin!
      end

      def cache!
      end

      def filesystem_path
        @filesystem_path ||= Pathname.new(path).expand_path(environment.project_path)
      end

    end
  end
end
