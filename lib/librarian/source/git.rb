require 'fileutils'
require 'pathname'
require 'digest'

require 'librarian/particularity'
require 'librarian/source/git/repository'
require 'librarian/source/local'

module Librarian
  module Source
    class Git

      include Particularity
      include Local

      DEFAULTS = {
        :ref => 'master'
      }

      attr_reader :uri, :ref

      def initialize(uri, options = {})
        @uri = uri
        @ref = options[:ref]
        @repository = nil
        @repository_cache_path = nil
      end

      def to_s
        "#{uri} at #{ref || DEFAULTS[:ref]}"
      end

      def cache!(dependencies)
        unless repository.git?
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath
          repository.clone!(uri)
        end
        repository.checkout!(ref || DEFAULTS[:ref])
      end

      def repository_cache_path
        @repository_cache_path ||= begin
          dir = Digest::MD5.hexdigest(uri)
          root_module.cache_path.join("source/git/#{dir}")
        end
      end

      def repository
        @repository ||= begin
          Repository.new(root_module, repository_cache_path)
        end
      end

      def path
        @path ||= repository.path
      end

    end
  end
end
