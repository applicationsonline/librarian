require 'librarian/version'
require 'librarian/dependency'
require 'librarian/particularity'
require 'librarian/source'
require 'librarian/specfile'
require 'librarian/ui'

module Librarian
  extend self

  class Error < Exception
  end

  class << self
    def abstract_method(*names)
      names.each do |name|
        define_method(name) { raise Exception, "Cannot use Librarian##{name} directly." }
      end
    end
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
      install_path.each_child do |c|
        debug { "Deleting #{project_relative_path_to(c)}" }
        c.rmtree unless c.file?
      end
    end
  end

  def install!
    specfile = Specfile.new(dsl_class, specfile_path)
    sources = specfile.dependencies.map{|d| d.source}.uniq
    sources.each do |s|
      debug { "Caching #{s}" }
      sdeps = specfile.dependencies.select{|d| d.source == s}.uniq
      s.cache!(sdeps)
    end
    specfile.dependencies.each do |d|
      debug { "Installing #{d.name}" }
      d.source.install!(d)
    end
  end

private

  def debug
    ui.debug "[Librarian] #{yield}"
  end

end
