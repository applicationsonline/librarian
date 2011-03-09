require 'librarian/manifest'
require 'librarian/mock/particularity'
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
          def install!
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
          if d = registry[dependency.name]
            d.map{|v| Manifest.new(self, dependency.name, v)}
          else
            nil
          end
        end

        def cache!(dependencies)
        end

        def to_s
          name
        end

      end
    end
  end
end
