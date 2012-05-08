require 'librarian/support/abstract_method'

module Librarian
  module Source
    # Requires that the including source class have methods:
    #   #path
    #   #environment
    module Local

      include Support::AbstractMethod

      abstract_method :path

      def manifests(name)
        manifest = manifest_class.new(self, name, filesystem_path)
        [manifest].compact
      end

      def manifest(name, version, dependencies)
        manifest = manifest_class.new(self, name, filesystem_path)
        manifest.version = version
        manifest.dependencies = dependencies
        manifest
      end

      def manifest_search_paths(name)
        paths = [filesystem_path, filesystem_path.join(name)]
        paths.select{|s| s.exist?}
      end

      def found_path(name)
        @_found_paths ||= { }
        @_found_paths[name] ||= begin
          paths = manifest_search_paths(name)
          paths.find{|p| manifest?(name, p)}
        end
      end

    private

      abstract_method :manifest? # (name, path) -> boolean

    end
  end
end
