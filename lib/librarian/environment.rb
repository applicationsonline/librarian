require "pathname"
require 'net/http'
require "uri"
require "etc"

require "librarian/helpers"
require "librarian/support/abstract_method"

require "librarian/error"
require "librarian/config"
require "librarian/lockfile"
require "librarian/logger"
require "librarian/specfile"
require "librarian/resolver"
require "librarian/dsl"
require "librarian/source"
require "librarian/version"
require "librarian/environment/runtime_cache"

module Librarian
  class Environment

    include Support::AbstractMethod

    attr_accessor :ui
    attr_reader :runtime_cache

    abstract_method :specfile_name, :dsl_class, :install_path

    def initialize(options = { })
      @pwd = options.fetch(:pwd) { Dir.pwd }
      @env = options.fetch(:env) { ENV.to_hash }
      @home = options.fetch(:home) { default_home }
      @project_path = options[:project_path]
      @runtime_cache = RuntimeCache.new
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

    def adapter_module
      implementation? or return
      self.class.name.split("::")[0 ... -1].inject(Object, &:const_get)
    end

    def adapter_name
      implementation? or return
      Helpers.camel_cased_to_dasherized(self.class.name.split("::")[-2])
    end

    def adapter_version
      implementation? or return
      adapter_module::VERSION
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

    def resolver(options = { })
      Resolver.new(self, resolver_options.merge(options))
    end

    def resolver_options
      {
        :cyclic => resolver_permit_cyclic_reslutions?,
      }
    end

    def resolver_permit_cyclic_reslutions?
      false
    end

    def tmp_path
      part = config_db["tmp"] || "tmp"
      project_path.join(part)
    end

    def cache_path
      tmp_path.join("librarian/cache")
    end

    def scratch_path
      tmp_path.join("librarian/scratch")
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
      adapter_module::Dsl
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
      no_proxy?(host) ? Net::HTTP : net_http_default_class
    end

    def inspect
      "#<#{self.class}:0x#{__id__.to_s(16)}>"
    end

  private

    def environment
      self
    end

    def implementation?
      self.class != ::Librarian::Environment
    end

    def default_home
      File.expand_path(ENV["HOME"] || Etc.getpwnam(Etc.getlogin).dir)
    end

    def no_proxy_list
      @no_proxy_list ||= begin
        list = ENV['NO_PROXY'] || ENV['no_proxy'] || ""
        list.split(/\s*,\s*/) + %w(localhost 127.0.0.1)
      end
    end

    def no_proxy?(host)
      no_proxy_list.any? do |host_addr|
        host.end_with?(host_addr)
      end
    end

    def net_http_default_class
      @net_http_default_class ||= begin
        p = http_proxy_uri
        p ? Net::HTTP::Proxy(p.host, p.port, p.user, p.password) : Net::HTTP
      end
    end

  end
end
