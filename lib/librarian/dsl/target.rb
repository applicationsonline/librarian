module Librarian
  class Dsl
    class Target

      SCOPABLES = [:sources]

      attr_reader :dependency_name, :dependency_type
      attr_reader :source_types, :source_types_map, :source_type_names, :source_shortcuts
      attr_reader :dependencies, :source_cache, *SCOPABLES

      def initialize(dsl)
        @dependency_name = dsl.dependency_name
        @dependency_type = dsl.dependency_type
        @source_types = dsl.source_types
        @source_types_map = Hash[source_types]
        @source_type_names = source_types.map{|t| t[0]}
        @source_shortcuts = dsl.source_shortcuts
        @dependencies = []
        @source_cache = {}
        SCOPABLES.each do |scopable|
          instance_variable_set(:"@#{scopable}", [])
        end
      end

      def dependency(name, *args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        source = source_from_options(options) || @sources.last
        unless source
          raise Error, "#{dependency_name} #{name} is specified without a source!"
        end
        dep = dependency_type.new(name, args, source)
        @dependencies << dep
      end

      def source(name, param = nil, options = {}, &block)
        name, param, options = *normalize_source_options(name, param, options)
        source = source_from_params(name, param, options)
        scope_or_directive(block) do
          @sources = @sources.dup << source
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

      def scope_or_directive(scoped_block = nil)
        unless scoped_block
          yield
        else
          scope do
            yield
            scoped_block.call
          end
        end
      end

      def normalize_source_options(name, param, options)
        if name.is_a?(Hash)
          extract_source_parts(name)
        elsif param.nil?
          extract_source_parts(source_shortcuts[name])
        else
          [name, param, options]
        end
      end

      # HACK:
      #   :source is a magic string!
      # NOTE:
      #   this method recurses when it finds a shortcut hash source.
      def extract_source_parts(options)
        if options.key?(:source)
          options = source_shortcuts[options[:source]]
          extract_source_parts(options)
        elsif name = source_type_names.find{|name| options.key?(name)}
          options = options.dup
          param = options.delete(name)
          [name, param, options]
        else
          nil
        end
      end

      def source_from_options(options)
        unless source_parts = extract_source_parts(options)
          nil
        else
          source_from_params(*source_parts)
        end
      end

      def source_from_params(name, param, options)
        source_cache[[name, param, options]] ||= begin
          type = source_types_map[name]
          type.new(param, options)
        end
      end

    end
  end
end
