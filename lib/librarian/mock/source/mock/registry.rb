require 'rubygems'

module Librarian
  module Mock
    module Source
      class Mock
        class Registry

          module Dsl

            class Top
              def initialize(sources)
                @sources = sources
              end
              def source(name, &block)
                @sources[name] ||= {}
                Source.new(@sources[name]).instance_eval(&block) if block
              end
            end

            class Source
              def initialize(source)
                @source = source
              end
              def spec(name, version = nil, &block)
                @source[name] ||= []
                unless version
                  Spec.new(@source[name]).instance_eval(&block) if block
                else
                  Spec.new(@source[name]).version(version, &block)
                end
                @source[name].sort! {|a, b| Gem::Version(a) <=> Gem::Version(b)}.reverse!
              end
            end

            class Spec
              def initialize(spec)
                @spec = spec
              end
              def version(name, &block)
                @spec << { :version => name, :dependencies => {} }
                Version.new(@spec.last[:dependencies]).instance_eval(&block) if block
              end
            end

            class Version
              def initialize(version)
                @version = version
              end
              def dependency(name, *requirement)
                @version[name] = requirement
              end
            end

            class << self
              def run!(sources, &block)
                Top.new(sources).instance_eval(&block) if block
              end
            end

          end

          class << self
            def clear!
              @sources = nil
            end
            def merge!(&block)
              @sources ||= {}
              Dsl.run!(@sources, &block) if block
            end
            def [](name)
              @sources ||= {}
              @sources[name] ||= {}
            end
          end

        end
      end
    end
  end
end
