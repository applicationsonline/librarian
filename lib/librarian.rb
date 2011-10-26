require 'pathname'

require 'librarian/helpers/debug'
require 'librarian/support/abstract_method'

require 'librarian/version'
require 'librarian/environment'

module Librarian
  extend self

  class << self
    def delegate(*names)
      options = names.pop
      to = options.delete(:to)
      names.each do |name|
        if name =~ /=$/
          module_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{name}(arg)
              #{to}.#{name.gsub(/=$/, "")} = arg
            end
          CODE
        else
          module_eval <<-CODE, __FILE__, __LINE__ + 1
            def #{name}(*args, &block)
              #{to}.#{name}(*args, &block)
            end
          CODE
        end
      end
    end
  end

  def environment_class
    self::Environment
  end

  def environment
    @environment ||= environment_class.new
  end

  methods = %w(
    ui
    ui=
    specfile_name
    dsl_class
    install_path
    project_path
    specfile_path
    specfile
    lockfile_name
    lockfile_path
    lockfile
    ephemeral_lockfile
    resolver
    cache_path
    project_relative_path_to
    spec_change_set
    ensure!
    clean!
    install!
    update!
    resolve!
    dsl
    dsl_class
    debug
  )

  delegate *methods, :to => :environment

end
