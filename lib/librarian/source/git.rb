require 'fileutils'
require 'pathname'
require 'digest'

require 'librarian/error'
require 'librarian/source/basic_api'
require 'librarian/source/git/repository'
require 'librarian/source/local'

module Librarian
  module Source
    class Git
      include BasicApi
      include Local

      lock_name 'GIT'
      spec_options [:ref, :path]

      DEFAULTS = {
        :ref => 'master'
      }

      attr_accessor :environment
      private :environment=

      attr_accessor :uri, :ref, :sha, :path
      private :uri=, :ref=, :sha=, :path=

      def initialize(environment, uri, options)
        self.environment = environment
        self.uri = uri
        self.ref = options[:ref] || DEFAULTS[:ref]
        self.sha = options[:sha]
        self.path = options[:path]

        @repository = nil
        @repository_cache_path = nil

        ref.kind_of?(String) or raise TypeError, "ref must be a String"
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

      def cache!
        repository_cached? and return or repository_cached!

        unless repository.git?
          repository.path.rmtree if repository.path.exist?
          repository.path.mkpath
          repository.clone!(uri)
          raise Error, "failed to clone #{uri}" unless repository.git?
        end

        # Probably unnecessary: nobody should be writing to our cache but us.
        # Just a precaution.
        repository_clean_once!

        unless sha
          repository_update_once!
          self.sha = fetch_sha_memo
        end

        unless repository.checked_out?(sha)
          repository_update_once! unless repository.has_commit?(sha)
          repository.checkout!(sha)
          # Probably unnecessary: if git fails to checkout, it should exit
          # nonzero, and we should expect Librarian::Posix::CommandFailure.
          raise Error, "failed to checkout #{sha}" unless repository.checked_out?(sha)
        end
      end

      # For tests
      def git_ops_count
        repository.git_ops_history.size
      end

    private

      attr_accessor :repository_cached
      alias repository_cached? repository_cached

      def repository_cached!
        self.repository_cached = true
      end

      def repository_cache_path
        @repository_cache_path ||= begin
          environment.cache_path + "source/git" + cache_key
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

      def repository_clean_once!
        remote = repository.default_remote
        runtime_cache.once ['repository-clean', uri, ref].to_s do
          repository.reset_hard!
          repository.clean!
        end
      end

      def repository_update_once!
        remote = repository.default_remote
        runtime_cache.once ['repository-update', uri, remote, ref].to_s do
          repository.fetch! remote
          repository.fetch! remote, :tags => true
        end
      end

      def fetch_sha_memo
        remote = repository.default_remote
        runtime_cache.memo ['fetch-sha', uri, remote, ref].to_s do
          repository.hash_from(remote, ref)
        end
      end

      def cache_key
        @cache_key ||= begin
          uri_part = uri
          ref_part = "##{ref}"
          key_source = [uri_part, ref_part].join
          Digest::MD5.hexdigest(key_source)[0..15]
        end
      end

      def runtime_cache
        @runtime_cache ||= environment.runtime_cache.keyspace(self.class.name)
      end

    end
  end
end
