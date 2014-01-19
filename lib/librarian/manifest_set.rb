require "librarian/algorithms"

module Librarian
  class ManifestSet

    class << self
      def shallow_strip(manifests, names)
        new(manifests).shallow_strip!(names).send(method_for(manifests))
      end
      def deep_strip(manifests, names)
        new(manifests).deep_strip!(names).send(method_for(manifests))
      end
      def shallow_keep(manifests, names)
        new(manifests).shallow_keep!(names).send(method_for(manifests))
      end
      def deep_keep(manifests, names)
        new(manifests).deep_keep!(names).send(method_for(manifests))
      end
      def cyclic?(manifests)
        manifests = Hash[manifests.map{|m| [m.name, m]}] if Array === manifests
        manifest_pairs = Hash[manifests.map{|k, m| [k, m.dependencies.map{|d| d.name}]}]
        adj_algs.cyclic?(manifest_pairs)
      end
      def sort(manifests)
        manifests = Hash[manifests.map{|m| [m.name, m]}] if Array === manifests
        manifest_pairs = Hash[manifests.map{|k, m| [k, m.dependencies.map{|d| d.name}]}]
        manifest_names = adj_algs.tsort_cyclic(manifest_pairs)
        manifest_names.map{|n| manifests[n]}
      end
    private
      def method_for(manifests)
        case manifests
        when Hash
          :to_hash
        when Array
          :to_a
        end
      end
      def adj_algs
        Algorithms::AdjacencyListDirectedGraph
      end
    end

    def initialize(manifests)
      self.index = Hash === manifests ? manifests.dup : index_by(manifests, &:name)
    end

    def to_a
      index.values
    end

    def to_hash
      index.dup
    end

    def dup
      self.class.new(index)
    end

    def shallow_strip(names)
      dup.shallow_strip!(names)
    end

    def shallow_strip!(names)
      assert_strings!(names)

      names.each do |name|
        index.delete(name)
      end
      self
    end

    def deep_strip(names)
      dup.deep_strip!(names)
    end

    def deep_strip!(names)
      strippables = dependencies_of(names)
      shallow_strip!(strippables)

      self
    end

    def shallow_keep(names)
      dup.shallow_keep!(names)
    end

    def shallow_keep!(names)
      assert_strings!(names)

      names = Set.new(names) unless Set === names
      index.reject! { |k, v| !names.include?(k) }
      self
    end

    def deep_keep(names)
      dup.conservative_strip!(names)
    end

    def deep_keep!(names)
      keepables = dependencies_of(names)
      shallow_keep!(keepables)

      self
    end

    def consistent?
      index.values.all? do |manifest|
        in_compliance_with?(manifest.dependencies)
      end
    end

    def in_compliance_with?(dependencies)
      dependencies.all? do |dependency|
        manifest = index[dependency.name]
        manifest && manifest.satisfies?(dependency)
      end
    end

  private

    attr_accessor :index

    def assert_strings!(names)
      non_strings = names.reject{|name| String === name}
      non_strings.empty? or raise TypeError, "names must all be strings"
    end

    # Straightforward breadth-first graph traversal algorithm.
    def dependencies_of(names)
      names = Array === names ? names.dup : names.to_a
      assert_strings!(names)

      deps = Set.new
      until names.empty?
        name = names.shift
        next if deps.include?(name)

        deps << name
        names.concat index[name].dependencies.map(&:name)
      end
      deps.to_a
    end

    def index_by(enum)
      Hash[enum.map{|obj| [yield(obj), obj]}]
    end

  end
end
