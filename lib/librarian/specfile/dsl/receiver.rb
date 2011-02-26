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

        def run(specfile = nil)
          if block_given?
            instance_eval(&Proc.new)
          else
            case specfile
            when Specfile
              instance_eval(specfile.path.read, specfile.path.to_s, 1)
            when String
              instance_eval(specfile)
            when Proc
              instance_eval(&specfile)
            end
          end
        end

      end
    end
  end
end
