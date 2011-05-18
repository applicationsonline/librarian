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

      class << self
        LOCK_NAME = 'GIT'
        def lock_name
          LOCK_NAME
        end
        def from_lock_options(options)
          new(options[:remote], options.reject{|k, v| k == :remote})
        end
      end

      DEFAULTS = {
        :ref => 'master'
      }

      attr_reader :uri, :ref, :sha

      def initialize(uri, options = {})
        @uri = uri
        @ref = options[:ref] || DEFAULTS[:ref]
        @sha = options[:sha]
        @repository = nil
        @repository_cache_path = nil
      end

      def to_s
        "#{uri}##{ref}"
      end

      def to_lock_options
        {:remote => uri, :ref => ref, :sha => sha}
      end

      def cache!(dependencies)
        unless repository.git?
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath
          repository.clone!(uri)
        end
        unless sha == repository.current_commit_hash
          repository.checkout!(sha || ref)
          @sha ||= repository.current_commit_hash
        end
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
