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
        module_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}(*args, &block)
            #{to}.#{name}(*args, &block)
          end
        CODE
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
    specfile_name
    install_path
    project_path
    specfile_path
    specfile
    lockfile_name
    lockfile_path
    lockfile
    ephemeral_lockfile
    cache_path
    ensure!
    clean!
    install!
    update!
    resolve!
  )

  delegate *methods, :to => :environment

end
