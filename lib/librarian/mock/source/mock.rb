require 'librarian/manifest'
require 'librarian/mock/source/mock/registry'

module Librarian
  module Mock
    module Source
      class Mock

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

        class << self
          LOCK_NAME = 'MOCK'
          def lock_name
            LOCK_NAME
          end
          def from_lock_options(environment, options)
            new(environment, options[:remote], options.reject{|k, v| k == :remote})
          end
        end

        attr_accessor :environment
        private :environment=
        attr_reader :name

        def initialize(environment, name, options)
          self.environment = environment
          @name = name
        end

        def to_s
          name
        end

        def ==(other)
          other &&
          self.class  == other.class &&
          self.name   == other.name
        end

        def to_spec_args
          [name, {}]
        end

        def to_lock_options
          {:remote => name}
        end

        def registry
          environment.registry[name]
        end

        def manifest(name, version, dependencies)
          Manifest.new(self, name, {:version => version, :dependencies => dependencies})
        end

        def manifests(name)
          if d = registry[name]
            d.map{|v| Manifest.new(self, name, v)}
          else
            nil
          end
        end

        def cache!(dependencies)
        end

        def install!(manifest)
        end

        def to_s
          name
        end

      end
    end
  end
end
