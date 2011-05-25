module Librarian
  class Resolution
    attr_reader :dependencies, :manifests, :manifests_index

    def initialize(dependencies, manifests)
      @dependencies, @manifests = dependencies, manifests
      @manifests_index = build_manifests_index(manifests)
    end

    def correct?
      manifests && manifests_consistent_with_dependencies? && manifests_internally_consistent?
    end

  private

    def build_manifests_index(manifests)
      Hash[manifests.map{|m| [m.name, m]}] if manifests
    end

    def manifests_consistent_with_dependencies?
      dependencies.all? do |dependency|
        manifest = manifests_index[dependency.name]
        dependency.satisfied_by?(manifest)
      end
    end

    def manifests_internally_consistent?
      manifests.all? do |manifest|
        manifest.dependencies.all? do |dependency|
          manifest = manifests_index[dependency.name]
          dependency.satisfied_by?(manifest)
        end
      end
    end

  end
end
