require "pathname"

require "librarian/helpers/debug"
require "librarian/support/abstract_method"

require "librarian/error"
require "librarian/lockfile"
require "librarian/specfile"
require "librarian/spec_change_set"
require "librarian/manifest_set"
require "librarian/resolver"
require "librarian/dsl"

require "librarian/action"

module Librarian
  class Environment

    include Support::AbstractMethod
    include Helpers::Debug

    attr_accessor :ui

    abstract_method :specfile_name, :dsl_class, :install_path

    def initialize(options = { })
      @project_path = options[:project_path]
    end

    def project_path
      @project_path ||= begin
        root = Pathname.new(Dir.pwd)
        root = root.dirname until root.join(specfile_name).exist? || root.dirname == root
        path = root.join(specfile_name)
        path.exist? ? root : nil
      end
    end

    def specfile_path
      project_path.join(specfile_name)
    end

    def specfile
      Specfile.new(self, specfile_path)
    end

    def lockfile_name
      "#{specfile_name}.lock"
    end

    def lockfile_path
      project_path.join(lockfile_name)
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

    def project_relative_path_to(path)
      Pathname.new(path).relative_path_from(project_path)
    end

    def spec_change_set(spec, lock)
      SpecChangeSet.new(self, spec, lock)
    end

    def spec
      specfile.read
    end

    def lock
      lockfile.read
    end

    def spec_consistent_with_lock?
      spec_change_set(spec, lock).same?
    end

    def ensure!
      Action::Ensure.new(self).run
    end

    def clean!
      Action::Clean.new(self).run
    end

    def install!
      resolve!
      Action::Install.new(self).run
    end

    def update!(options)
      Action::Update.new(self, :names => options[:names]).run
    end

    def resolve!(options = {})
      Action::Resolve.new(self, :force => options[:force]).run
    end

    def install_consistent_resolution!
      Action::Install.new(self).run
    end

    def dsl(&block)
      dsl_class.run(self, &block)
    end

    def dsl_class
      self.class.name.split("::")[0 ... -1].inject(Object) { |constant, fragment| constant.const_get(fragment) }::Dsl
    end

  private

    def environment
      self
    end

  end
end
