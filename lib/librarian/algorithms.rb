require "set"
require "tsort"

module Librarian
  module Algorithms

    class GraphHash < Hash
      include TSort
      def tsort_each_node(&block)
        keys.sort.each(&block) # demand determinism
      end
      def tsort_each_child(node, &block)
        children = self[node]
        children && children.sort.each(&block) # demand determinism
      end
      class << self
        def from(hash)
          o = new
          hash.each{|k, v| o[k] = v}
          o
        end
      end
    end

    module AdjacencyListDirectedGraph
      extend self

      def cyclic?(graph)
        each_cyclic_strongly_connected_component_set(graph).any?
      end

      # Topological sort of the graph with an approximately minimal feedback arc
      # set removed.
      def tsort_cyclic(graph)
        fag = feedback_arc_graph(graph)
        reduced_graph = subtract_edges_graph(graph, fag)
        GraphHash.from(reduced_graph).tsort
      end

      # Returns an approximately minimal feedback arc set, lifted into a graph.
      def feedback_arc_graph(graph)
        edges_to_graph(feedback_arc_set(graph))
      end

      # Returns an approximately minimal feedback arc set.
      def feedback_arc_set(graph)
        fas = feedback_arc_set_step0(graph)
        feedback_arc_set_step1(graph, fas)
      end

      private

      def edges_to_graph(edges)
        graph = {}
        edges.each do |(u, v)|
          graph[u] ||= []
          graph[u] << v
          graph[v] ||= nil
        end
        graph
      end

      def subtract_edges_graph(graph, edges_graph)
        xgraph = {}
        graph.each do |n, vs|
          dests = edges_graph[n]
          xgraph[n] = !vs ? vs : !dests ? vs : vs - dests
        end
        xgraph
      end

      def each_cyclic_strongly_connected_component_set(graph)
        return enum_for(__method__, graph) unless block_given?
        GraphHash.from(graph).each_strongly_connected_component do |scc|
          if scc.size == 1
            n = scc.first
            vs = graph[n] or next
            vs.include?(n) or next
          end
          yield scc
        end
      end

      # Partitions the graph into its strongly connected component subgraphs,
      # removes the acyclic single-vertex components (multi-vertex components
      # are guaranteed to be cyclic), and yields each cyclic strongly connected
      # component.
      def each_cyclic_strongly_connected_component_graph(graph)
        return enum_for(__method__, graph) unless block_given?
        each_cyclic_strongly_connected_component_set(graph) do |scc|
          sccs = scc.to_set
          sccg = GraphHash.new
          scc.each do |n|
            vs = graph[n]
            sccg[n] = vs && vs.select{|v| sccs.include?(v)}
          end
          yield sccg
        end
      end

      # The 0th step of computing a feedback arc set: pick out vertices whose
      # removals will make the graph acyclic.
      def feedback_arc_set_step0(graph)
        fas = []
        each_cyclic_strongly_connected_component_graph(graph) do |scc|
          scc.keys.sort.each do |n| # demand determinism
            vs = scc[n] or next
            vs.size > 0 or next
            vs.sort! # demand determinism
            fas << [n, vs.shift]
            break
          end
        end
        fas
      end

      # The 1st step of computing a feedback arc set: pick out vertices from the
      # 0th step whose removals turn out to be unnecessary.
      def feedback_arc_set_step1(graph, fas)
        reduced_graph = subtract_edges_graph(graph, edges_to_graph(fas))
        fas.select do |(u, v)|
          reduced_graph[u] ||= []
          reduced_graph[u] << v
          cyclic = cyclic?(reduced_graph)
          reduced_graph[u].pop if cyclic
          cyclic
        end
      end

    end

  end
end
