require 'librarian/source/local'

module Librarian
  module Source
    class Path

      include Local

      class << self
        LOCK_NAME = 'PATH'
        def lock_name
          LOCK_NAME
        end
        def from_lock_options(environment, options)
          new(environment, options[:remote], options.reject{|k, v| k == :remote})
        end
      end

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

      def cache!(dependencies)
      end

      def filesystem_path
        @filesystem_path ||= Pathname.new(path).expand_path(environment.project_path)
      end

    end
  end
end
