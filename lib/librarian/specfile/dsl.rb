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
            define_method(:source) do |*args, &block|
              target.source(*args, &block)
            end
            target.source_types.each do |source_type|
              name = source_type[0]
              define_method(name) do |*args, &block|
                target.source(name, *args, &block)
              end
            end
          end
        end
      end

      class Target
        SCOPABLES = [:sources]

        attr_reader :dependency_name, :dependency_type, :source_types, :dependencies

        def initialize(dependency_name, dependency_type, source_types)
          @dependency_name = dependency_name
          @dependency_type = dependency_type
          @source_types = source_types
          @dependencies = []
          @sources = []
        end

        def dependency(name, *args)
          options = args.last.is_a?(Hash) ? args.pop : {}
          source = source_from_options(options) || @sources.last
          dep = dependency_type.new(name, args, source)
          @dependencies << dep
        end

        def source(name, param = nil, options = {})
          if name.is_a?(Hash)
            type, name, param, options = *extract_source_parts(name)
          else
            type = source_type_from_name(name)
          end
          source = type.new(param, options)
          if !block_given?
            @sources = @sources.dup << source
          else
            scope do
              @sources = @sources.dup << source
              yield
            end
          end
        end

      private

        def scope
          currents = { }
          SCOPABLES.each do |scopable|
            currents[scopable] = instance_variable_get(:"@#{scopable}").dup
          end
          yield
        ensure
          SCOPABLES.reverse.each do |scopable|
            instance_variable_set(:"@#{scopable}", currents[scopable])
          end
        end

        def source_type_from_name(name)
          source_types.select{|t| t[0] == name}.first[1]
        end

        def extract_source_parts(options)
          unless type = source_types.select{|t| options.key?(t[0])}.first
            nil
          else
            name, type = *type
            options = options.dup
            param = options.delete(name)
            [type, name, param, options]
          end
        end

        def source_from_options(options)
          unless source_parts = extract_source_parts(options)
            nil
          else
            type, name, param, options = *source_parts
            type.new(param, options)
          end
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
