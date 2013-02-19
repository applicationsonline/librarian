require 'fileutils'
require 'pathname'
require 'digest'

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
        end
        repository.reset_hard!
        repository.clean!
        unless repository.checked_out?(sha)
          remote = repository.default_remote
          repository.fetch!(remote)
          repository.fetch!(remote, :tags => true)

          self.sha = repository.hash_from(remote, ref) unless sha
          repository.checkout!(sha) unless repository.checked_out?(sha)

          raise Error, "failed to checkout #{sha}" unless repository.checked_out?(sha)
        end
      end

    private

      attr_accessor :repository_cached
      alias repository_cached? repository_cached

      def repository_cached!
        self.repository_cached = true
      end

      def repository_cache_path
        @repository_cache_path ||= begin
          environment.cache_path.join("source/git/#{cache_key}")
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

      def cache_key
        @cache_key ||= begin
          uri_part = uri
          path_part = "/#{path}" if path
          ref_part = "##{ref}"
          key_source = [uri_part, path_part, ref_part].join
          Digest::MD5.hexdigest(key_source)[0..15]
        end
      end

    end
  end
end
