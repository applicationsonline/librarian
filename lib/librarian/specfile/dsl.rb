module Librarian
  class Specfile
    class Dsl

      class Receiver
        def initialize(target)
          singleton_class = class << self; self end
          singleton_class.class_eval do
            define_method(target.dependency_name) do |*args, &block|
              target.dependency(*args, &block)
            end
          end
        end
      end

      class Target
        attr_reader :dependency_name, :dependency_type, :source_types, :dependencies

        def initialize(dependency_name, dependency_type, source_types)
          @dependency_name = dependency_name
          @dependency_type = dependency_type
          @source_types = source_types
          @dependencies = []
        end

        def dependency(name, *args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          source = source_from_options(options)
          dep = dependency_type.new(name, args, source)
          @dependencies << dep
        end

        def source_from_options(options)
          type = source_types.select{|t| options.key?(t[0])}.first
          name, type = *type
          type.new(options[name], options)
        end
      end

      class << self
        def run(specfile)
          new.run(specfile)
        end

      private

        def dependency(options)
          dependency_name = options.keys.first
          dependency_type = options[dependency_name]
          singleton_class = class << self; self end
          singleton_class.instance_eval do
            define_method(:dependency_name) { dependency_name }
            define_method(:dependency_type) { dependency_type }
          end
        end

        def source(options)
          name = options.keys.first
          type = options[name]
          types = respond_to?(:source_types) ? source_types : []
          types << [name, type]
          singleton_class = class << self; self end
          singleton_class.instance_eval do
            define_method(:source_types) { types }
          end
        end
      end

      def dependency_name
        self.class.dependency_name
      end

      def dependency_type
        self.class.dependency_type
      end

      def source_types
        self.class.source_types
      end

      def run(specfile)
        Target.new(dependency_name, dependency_type, source_types).tap do |target|
          Receiver.new(target).instance_eval(specfile.path.read, specfile.path.to_s, 1)
        end
      end

    end
  end
end
