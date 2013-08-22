require 'rubygems'

require 'librarian/manifest_version'

module Librarian
  class Manifest
    attr_accessor :source, :name, :extra
    private :source=, :name=, :extra=

    def initialize(source, name, extra = nil)
      assert_name_valid! name

      self.source = source
      self.name = name
      self.extra = extra
    end

    def to_s
      "#{name}/#{version} <#{source}>"
    end

    def version
      defined_version || fetched_version
    end

    def version=(version)
      self.defined_version = _normalize_version(version)
    end

    def version?
      return unless defined_version

      defined_version == fetched_version
    end

    def latest
      @latest ||= source.manifests(name).first
    end

    def outdated?
      latest.version > version
    end

    def dependencies
      defined_dependencies || fetched_dependencies
    end

    def dependencies=(dependencies)
      self.defined_dependencies = _normalize_dependencies(dependencies)
    end

    def dependencies?
      return unless defined_dependencies

      defined_dependencies.zip(fetched_dependencies).all? do |(a, b)|
        a.name == b.name && a.requirement == b.requirement
      end
    end

    def satisfies?(dependency)
      dependency.requirement.satisfied_by?(version)
    end

    def install!
      source.install!(self)
    end

  private

    attr_accessor :defined_version, :defined_dependencies

    def environment
      source.environment
    end

    def fetched_version
      @fetched_version ||= _normalize_version(fetch_version!)
    end

    def fetched_dependencies
      @fetched_dependencies ||= _normalize_dependencies(fetch_dependencies!)
    end

    def fetch_version!
      source.fetch_version(name, extra)
    end

    def fetch_dependencies!
      source.fetch_dependencies(name, version, extra)
    end

    def _normalize_version(version)
      environment.adapter_manifest_version.new(version)
    end

    def _normalize_dependencies(dependencies)
      if Hash === dependencies
        dependencies = dependencies.map{|k, v| Dependency.new(k, v, nil)}
      end
      dependencies.sort_by(&:name)
    end

    def assert_name_valid!(name)
      name =~ /\A\S(?:.*\S)?\z/ and return

      raise ArgumentError, "name (#{name.inspect}) must be sensible"
    end

  end
end
