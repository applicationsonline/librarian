require 'pathname'

require 'librarian/helpers/debug'
require 'librarian/support/abstract_method'

require 'librarian/version'
require 'librarian/dependency'
require 'librarian/particularity'
require 'librarian/resolver'
require 'librarian/source'
require 'librarian/specfile'
require 'librarian/lockfile'
require 'librarian/ui'

module Librarian
  extend self

  include Support::AbstractMethod
  include Helpers::Debug

  class Error < StandardError
  end

  attr_accessor :ui

  abstract_method :specfile_name, :dsl_class, :install_path

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

  def resolver
    Resolver.new(self)
  end

  def cache_path
    project_path.join('tmp/librarian/cache')
  end

  def project_relative_path_to(path)
    Pathname.new(path).relative_path_from(project_path)
  end

  def ensure!
    unless project_path
      raise Error, "Cannot find #{specfile_name}!"
    end
  end

  def clean!
    if cache_path.exist?
      debug { "Deleting #{project_relative_path_to(cache_path)}" }
      cache_path.rmtree
    end
    if install_path.exist?
      install_path.children.each do |c|
        debug { "Deleting #{project_relative_path_to(c)}" }
        c.rmtree unless c.file?
      end
    end
    if lockfile_path.exist?
      debug { "Deleting #{project_relative_path_to(lockfile_path)}" }
      lockfile_path.rmtree
    end
  end

  def install!
    unless lockfile_path.exist?
      resolve!
    end
    manifests = lockfile.load(lockfile_path.read).manifests
    manifests.each do |manifest|
      manifest.source.cache!([manifest])
    end
    manifests.each do |manifest|
      manifest.install!
    end
  end

  def resolve!
    spec = specfile.read
    resolution = resolver.resolve(spec)
    unless resolution.correct?
      ui.info { "Could not resolve the dependencies." }
    else
      lockfile_text = lockfile.save(resolution)
      debug { "Bouncing #{lockfile_name}" }
      bounced_lockfile_text = lockfile.save(lockfile.load(lockfile_text))
      unless bounced_lockfile_text == lockfile_text
        debug { "lockfile_text: \n#{lockfile_text}"}
        debug { "bounced_lockfile_text: \n#{bounced_lockfile_text}"}
        raise Error, "Cannot bounce #{lockfile_name}!"
      end
      lockfile_path.open('wb') { |f| f.write(lockfile_text) }
    end
  end

  def dsl(&block)
    dsl_class.run(&block)
  end

  def dsl_class
    self::Dsl
  end

private

  def root_module
    self
  end

end
