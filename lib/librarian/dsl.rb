require 'librarian/dependency'
require 'librarian/dsl/receiver'
require 'librarian/dsl/target'

module Librarian
  class Dsl

    class Error < Exception
    end

    attr_accessor :environment
    private :environment=

    class << self

      def run(environment, specfile = nil, precache_sources = [], &block)
        new(environment).run(specfile, precache_sources, &block)
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

    def initialize(environment)
      self.environment = environment
    end

    def run(specfile = nil, sources = [])
      specfile, sources = nil, specfile if specfile.kind_of?(Array) && sources.empty?

      Target.new(self).tap do |target|
        target.precache_sources(sources)
        debug_named_source_cache("Pre-Cached Sources", target)

        specfile ||= Proc.new if block_given?
        receiver = Receiver.new(target)
        receiver.run(specfile)

        debug_named_source_cache("Post-Cached Sources", target)
      end.to_spec
    end

    def debug_named_source_cache(name, target)
      source_cache = target.source_cache
      debug { "#{name}:" }
      source_cache.each do |key, value|
        type = key[0]
        attributes = key[1...key.size]
        debug { "  #{key.inspect}" }
      end
    end

  private

    def debug(*args, &block)
      environment.logger.debug(*args, &block)
    end

  end
end
