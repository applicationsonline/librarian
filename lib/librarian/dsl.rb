require 'librarian/dependency'
require 'librarian/dsl/receiver'
require 'librarian/dsl/target'

module Librarian
  class Dsl

    class Error < Exception
    end

    class << self

      def run(specfile = nil, precache_sources = [], &block)
        new.run(specfile, precache_sources, &block)
      end

    private

      def dependency(name)
        dependency_name = name
        dependency_type = Dependency
        singleton_class = class << self; self end
        singleton_class.instance_eval do
          define_method(:dependency_name) { dependency_name }
          define_method(:dependency_type) { dependency_type }
        end
      end

      define_method(:source_types) { [] }

      def source(options)
        name = options.keys.first
        type = options[name]
        types = source_types
        types << [name, type]
        singleton_class = class << self; self end
        singleton_class.instance_eval do
          define_method(:source_types) { types }
        end
      end

      define_method(:source_shortcuts) { {} }

      def shortcut(name, options)
        instances = source_shortcuts
        instances[name] = options
        singleton_class = class << self; self end
        singleton_class.instance_eval do
          define_method(:source_shortcuts) { instances }
        end
      end

      def delegate_to_class(*names)
        names.each do |name|
          define_method(name) { self.class.send(name) }
        end
      end

    end

    delegate_to_class :dependency_name, :dependency_type, :source_types, :source_shortcuts

    def run(specfile = nil, sources = [])
      Target.new(self).tap do |target|
        target.precache_sources(sources)
        receiver = Receiver.new(target)
        if block_given?
          receiver.run(&Proc.new)
        else
          receiver.run(specfile)
        end
      end.to_spec
    end

  end
end
