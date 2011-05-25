module Librarian
  class Resolution
    attr_reader :dependencies, :manifests

    def initialize(dependencies, manifests)
      @dependencies, @manifests = dependencies, manifests
    end

    def correct?
      manifests && begin
        manifests_hash = Hash[manifests.map{|m| [m.name, m]}]
        deps_match = dependencies.all? do |dependency|
          manifest = manifests_hash[dependency.name]
          dependency.satisfied_by?(manifest)
        end
        mans_match = manifests.all? do |manifest|
          manifest.dependencies.all? do |dependency|
            manifest = manifests_hash[dependency.name]
            dependency.satisfied_by?(manifest)
          end
        end
        deps_match && mans_match
      end
    end
  end
end
