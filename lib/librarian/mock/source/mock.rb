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
          registry[dependency.name].map{|v| Manifest.new(self, dependency.name, v)}
        end

        def cache!(dependencies)
        end

      end
    end
  end
end
