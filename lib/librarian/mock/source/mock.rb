require 'rubygems'

require 'librarian/manifest'
require 'librarian/mock/particularity'

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
              def spec(name, &block)
                @source[name] ||= []
                Spec.new(@source[name]).instance_eval(&block) if block
                @source[name].sort! {|a, b| Gem::Version(a) <=> Gem::Version(b)}
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

        class Manifest < Manifest
          attr_reader :manifest
          def initialize(source, name, manifest)
            super(source, name)
            @manifest = manifest
          end
          def fetch_version!
            manifest[:version]
          end
          def fetch_dependencies!
            manifest[:dependencies]
          end
        end

        include Particularity

        attr_reader :name

        def initialize(name, options)
          @name = name
        end

        def registry
          Registry[name]
        end

        def manifests(dependency)
          registry[dependency.name].map{|v| Manifest.new(self, dependency.name, v)}
        end

        def cache!(dependencies)
        end

      end
    end
  end
end
