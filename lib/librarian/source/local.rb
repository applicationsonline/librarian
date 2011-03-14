require 'librarian/support/abstract_method'

module Librarian
  module Source
    # Requires that the including source class have methods:
    #   #path
    #   #root_module
    module Local

      include Support::AbstractMethod

      abstract_method :path

      def manifests(dependency)
        manifest = manifest_class.create(self, dependency, path)
        [manifest].compact
      end

      def manifest_search_paths(dependency)
        paths = [path, path.join(dependency.name)]
        paths.select{|s| s.exist?}
      end

    end
  end
end
