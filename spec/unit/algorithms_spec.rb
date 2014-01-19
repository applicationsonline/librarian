require "librarian/algorithms"

module Librarian
  module Algorithms

    describe AdjacencyListDirectedGraph do

      describe :cyclic? do
        subject(:result) { described_class.cyclic?(graph) }

        context "with an empty graph" do
          let(:graph) { { } }
          it { should be false }
        end

        context "with a 1-node acyclic graph" do
          let(:graph) { { ?a => nil } }
          it { should be false }
        end

        context "with a 1-node cyclic graph" do
          let(:graph) { { ?a => [?a] } }
          it { should be true }
        end

        context "with a 2-node no-edge graph" do
          let(:graph) { { ?a => nil, ?b => nil } }
          it { should be false }
        end

        context "with a 2-node acyclic graph" do
          let(:graph) { { ?a => [?b], ?b => nil } }
          it { should be false }
        end

        context "with a 2-node cyclic graph" do
          let(:graph) { { ?a => [?b], ?b => [?a] } }
          it { should be true }
        end

        context "with a 2-scc graph" do
          let(:graph) { { ?a => [?b], ?b => [?a], ?c => [?d, ?b], ?d => [?c] } }
          it { should be true }
        end

      end

      describe :feedback_arc_set do
        subject(:result) { described_class.feedback_arc_set(graph) }

        context "with an empty graph" do
          let(:graph) { { } }
          it { should be_empty }
        end

        context "with a 1-node acyclic graph" do
          let(:graph) { { ?a => nil } }
          it { should be_empty }
        end

        context "with a 1-node cyclic graph" do
          let(:graph) { { ?a => [?a] } }
          it { should be == [[?a, ?a]] }
        end

        context "with a 2-node no-edge graph" do
          let(:graph) { { ?a => nil, ?b => nil } }
          it { should be_empty }
        end

        context "with a 2-node acyclic graph" do
          let(:graph) { { ?a => [?b], ?b => nil } }
          it { should be_empty }
        end

        context "with a 2-node cyclic graph" do
          let(:graph) { { ?a => [?b], ?b => [?a] } }
          it { should be == [[?a, ?b]] } # based on the explicit sort
        end

        context "with a 2-scc graph" do
          let(:graph) { { ?a => [?b], ?b => [?a], ?c => [?d, ?b], ?d => [?c] } }
          it { should be == [[?a, ?b], [?c, ?d]] }
        end

      end

      describe :tsort_cyclic do
        subject(:result) { described_class.tsort_cyclic(graph) }

        context "with an empty graph" do
          let(:graph) { { } }
          it { should be == [] }
        end

        context "with a 1-node acyclic graph" do
          let(:graph) { { ?a => nil } }
          it { should be == [?a] }
        end

        context "with a 1-node cyclic graph" do
          let(:graph) { { ?a => [?a] } }
          it { should be == [?a] }
        end

        context "with a 2-node no-edge graph" do
          let(:graph) { { ?a => nil, ?b => nil } }
          it { should be == [?a, ?b] }
        end

        context "with a 2-node acyclic graph" do
          let(:graph) { { ?a => [?b], ?b => nil } }
          it { should be == [?b, ?a] } # based on the explicit sort
        end

        context "with a 2-node cyclic graph" do
          let(:graph) { { ?a => [?b], ?b => [?a] } }
          it { should be == [?a, ?b] } # based on the explicit sort
        end

        context "with a 2-scc graph" do
          let(:graph) { { ?a => [?b], ?b => [?a], ?c => [?d, ?b], ?d => [?c] } }
          it { should be == [?a, ?b, ?c, ?d] }
        end

      end

    end

  end
end
