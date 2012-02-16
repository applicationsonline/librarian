require 'fileutils'
require 'pathname'
require 'digest'

require 'librarian/source/git/repository'
require 'librarian/source/local'

module Librarian
  module Source
    class Git

      include Local

      class << self
        LOCK_NAME = 'GIT'
        def lock_name
          LOCK_NAME
        end
        def from_lock_options(environment, options)
          new(environment, options[:remote], options.reject{|k, v| k == :remote})
        end
      end

      DEFAULTS = {
        :ref => 'master'
      }

      attr_accessor :environment
      private :environment=
      attr_reader :uri, :ref, :sha, :path

      def initialize(environment, uri, options = {})
        self.environment = environment
        @uri = uri
        @ref = options[:ref] || DEFAULTS[:ref]
        @sha = options[:sha]
        @path = options[:path]
        @repository = nil
        @repository_cache_path = nil
      end

      def to_s
        path ? "#{uri}##{ref}(#{path})" : "#{uri}##{ref}"
      end

      def ==(other)
        other &&
        self.class  == other.class  &&
        self.uri    == other.uri    &&
        self.ref    == other.ref    &&
        self.path   == other.path   &&
        (self.sha.nil? || other.sha.nil? || self.sha == other.sha)
      end

      def to_spec_args
        options = {}
        options.merge!(:ref => ref) if ref != DEFAULTS[:ref]
        options.merge!(:path => path) if path
        [uri, options]
      end

      def to_lock_options
        options = {:remote => uri, :ref => ref, :sha => sha}
        options.merge!(:path => path) if path
        options
      end

      def pinned?
        !!sha
      end

      def unpin!
        @sha = nil
      end

      def cache!(dependencies)
        unless repository.git?
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath
          repository.clone!(uri)
        end
        unless sha == repository.current_commit_hash
          repository.fetch!(:tags => true)
          repository.fetch!
          repository.merge_all_remote_branches!
          repository.checkout!(repository.hash_from(sha || ref), :force => true)
          @sha ||= repository.current_commit_hash
        end
      end

      def repository_cache_path
        @repository_cache_path ||= begin
          dir = path ? "#{uri}/#{path}" : uri
          dir = Digest::MD5.hexdigest(dir)
          environment.cache_path.join("source/git/#{dir}")
        end
      end

      def repository
        @repository ||= begin
          Repository.new(environment, repository_cache_path)
        end
      end

      def filesystem_path
        @filesystem_path ||= path ? repository.path.join(path) : repository.path
      end

    end
  end
end
