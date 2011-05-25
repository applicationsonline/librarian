module Librarian
  class ManifestSet

    class << self
      def shallow_strip(manifests, names)
        new(manifests).shallow_strip!(names).manifests
      end
      def deep_strip(manifests, names)
        new(manifests).deep_strip!(names).manifests
      end
    end

    attr_reader :manifests, :manifests_index

    def initialize(manifests)
      @manifests = manifests.dup
      @manifests_index = Hash[manifests.map{|m| [m.name, m]}]
    end

    def shallow_strip!(names)
      names = [names] unless Array === names
      names.each do |name|
        manifests_index.delete(name)
      end
      @manifests = manifests_index.values
      self
    end

    def deep_strip!(names)
      names = [names] unless Array === names
      names = names.dup
      until names.empty?
        name = names.shift
        manifest = manifests_index.delete(name)
        manifest.dependencies.each do |dependency|
          names << dependency.name
        end
      end
      @manifests = manifests_index.values
      self
    end

  end
end
