require 'librarian/specfile/dsl/receiver'
require 'librarian/specfile/dsl/target'

module Librarian
  class Specfile
    class Dsl

      class << self
        def run(specfile = nil, &block)
          new.run(specfile, &block)
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

      def run(specfile = nil)
        Target.new(dependency_name, dependency_type, source_types).tap do |target|
          receiver = Receiver.new(target)
          if block_given?
            receiver.run(&Proc.new)
          else
            receiver.run(specfile)
          end
        end
      end

    end
  end
end
