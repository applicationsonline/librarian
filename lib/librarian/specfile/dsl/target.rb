module Librarian
  class Specfile
    class Dsl
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
    end
  end
end
