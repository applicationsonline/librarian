require "pathname"

module Librarian
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

      def run(specfile = nil)
        specfile = Proc.new if block_given?

        case specfile
        when Pathname
          instance_eval(File.read(specfile), specfile.to_s, 1)
        when String
          instance_eval(specfile)
        when Proc
          instance_eval(&specfile)
        else
          raise ArgumentError, "specfile must be a #{Pathname}, #{String}, or #{Proc} if no block is given (it was #{specfile.inspect})"
        end
      end

    end
  end
end
