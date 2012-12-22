require "pathname"
require 'net/http'
require "uri"

require "librarian/support/abstract_method"

require "librarian/error"
require "librarian/config"
require "librarian/lockfile"
require "librarian/logger"
require "librarian/specfile"
require "librarian/resolver"
require "librarian/dsl"
require "librarian/source"

module Librarian
  class Environment

    include Support::AbstractMethod

    attr_accessor :ui

    abstract_method :specfile_name, :dsl_class, :install_path

    def initialize(options = { })
      @pwd = options.fetch(:pwd) { Dir.pwd }
      @env = options.fetch(:env) { ENV.to_hash }
      @home = options.fetch(:home) { File.expand_path("~") }
      @project_path = options[:project_path]
      @specfile_name = options[:specfile_name]
    end

    def logger
      @logger ||= Logger.new(self)
    end

    def config_db
      @config_db ||= begin
        Config::Database.new(adapter_name,
          :pwd => @pwd,
          :env => @env,
          :home => @home,
          :project_path => @project_path,
          :specfile_name => default_specfile_name
        )
      end
    end

    def default_specfile_name
      @default_specfile_name ||= begin
        capped = adapter_name.capitalize
        "#{capped}file"
      end
    end

    def project_path
      config_db.project_path
    end

    def specfile_name
      config_db.specfile_name
    end

    def specfile_path
      config_db.specfile_path
    end

    def specfile
      Specfile.new(self, specfile_path)
    end

    def adapter_name
      nil
    end

    def lockfile_name
      config_db.lockfile_name
    end

    def lockfile_path
      config_db.lockfile_path
    end

    def lockfile
      Lockfile.new(self, lockfile_path)
    end

    def ephemeral_lockfile
      Lockfile.new(self, nil)
    end

    def resolver
      Resolver.new(self)
    end

    def cache_path
      project_path.join("tmp/librarian/cache")
    end

    def scratch_path
      project_path.join("tmp/librarian/scratch")
    end

    def project_relative_path_to(path)
      Pathname.new(path).relative_path_from(project_path)
    end

    def spec
      specfile.read
    end

    def lock
      lockfile.read
    end

    def dsl(*args, &block)
      dsl_class.run(self, *args, &block)
    end

    def dsl_class
      self.class.name.split("::")[0 ... -1].inject(Object, &:const_get)::Dsl
    end

    def version
      VERSION
    end

    def config_keys
      %[
      ]
    end

    # The HTTP proxy specified in the environment variables:
    # * HTTP_PROXY
    # * HTTP_PROXY_USER
    # * HTTP_PROXY_PASS
    # Adapted from:
    #   https://github.com/rubygems/rubygems/blob/v1.8.24/lib/rubygems/remote_fetcher.rb#L276-293
    def http_proxy_uri
      @http_proxy_uri ||= begin
        keys = %w( HTTP_PROXY HTTP_PROXY_USER HTTP_PROXY_PASS )
        env = Hash[ENV.
          map{|k, v| [k.upcase, v]}.
          select{|k, v| keys.include?(k)}.
          reject{|k, v| v.nil? || v.empty?}]

        uri = env["HTTP_PROXY"] or return
        uri = "http://#{uri}" unless uri =~ /^(https?|ftp|file):/
        uri = URI.parse(uri)
        uri.user ||= env["HTTP_PROXY_USER"]
        uri.password ||= env["HTTP_PROXY_PASS"]
        uri
      end
    end

    def net_http_class(host)
      return Net::HTTP if no_proxy?(host)

      @net_http_class ||= begin
        p = http_proxy_uri
        p ? Net::HTTP::Proxy(p.host, p.port, p.user, p.password) : Net::HTTP
      end
    end

  private

    def environment
      self
    end

    def no_proxy?(host)
      @no_proxy ||= begin
        list = ENV['NO_PROXY'] || ENV['no_proxy'] || ""
        list.split(/\s*,\s*/) + %w(localhost 127.0.0.1)
      end
      @no_proxy.any? do |host_addr|
        host.match(Regexp.quote(host_addr)+'$')
      end
    end

  end
end
