require 'librarian'

module Librarian
  describe ManifestSet do

    describe ".new" do
      let(:jelly) { double(:name => "jelly") }
      let(:butter) { double(:name => "butter") }
      let(:jam) { double(:name => "jam") }

      let(:array) { [jelly, butter, jam] }
      let(:hash) { {"jelly" => jelly, "butter" => butter, "jam" => jam} }

      context "with an array" do
        let(:set) { described_class.new(array) }

        it "should give back the array" do
          expect(set.to_a).to match_array( array )
        end

        it "should give back the hash" do
          expect(set.to_hash).to eq hash
        end
      end

      context "with a hash" do
        let(:set) { described_class.new(hash) }

        it "should give back the array" do
          expect(set.to_a).to match_array( array )
        end

        it "should give back the hash" do
          expect(set.to_hash).to eq hash
        end
      end
    end

    # Does not trace dependencies.
    # That's why it's "shallow".
    describe "#shallow_strip!" do
      let(:jelly) { double(:name => "jelly") }
      let(:butter) { double(:name => "butter") }
      let(:jam) { double(:name => "jam") }

      let(:set) { described_class.new([jelly, butter, jam]) }

      it "should not do anything when given no names" do
        set.shallow_strip!([])

        expect(set.to_a).to match_array( [jelly, butter, jam] )
      end

      it "should remove only the named elements" do
        set.shallow_strip!(["butter", "jam"])

        expect(set.to_a).to match_array( [jelly] )
      end

      it "should allow removing all the elements" do
        set.shallow_strip!(["jelly", "butter", "jam"])

        expect(set.to_a).to match_array( [] )
      end
    end

    # Does not trace dependencies.
    # That's why it's "shallow".
    describe "#shallow_keep!" do
      let(:jelly) { double(:name => "jelly") }
      let(:butter) { double(:name => "butter") }
      let(:jam) { double(:name => "jam") }

      let(:set) { described_class.new([jelly, butter, jam]) }

      it "should empty the set when given no names" do
        set.shallow_keep!([])

        expect(set.to_a).to match_array( [] )
      end

      it "should keep only the named elements" do
        set.shallow_keep!(["butter", "jam"])

        expect(set.to_a).to match_array( [butter, jam] )
      end

      it "should allow keeping all the elements" do
        set.shallow_keep!(["jelly", "butter", "jam"])

        expect(set.to_a).to match_array( [jelly, butter, jam] )
      end
    end

    describe "#deep_strip!" do
      def man(o)
        k, v = o.keys.first, o.values.first
        double(k, :name => k, :dependencies => deps(v))
      end

      def deps(names)
        names.map{|n| double(:name => n)}
      end

      let(:a) { man("a" => %w[b c]) }
      let(:b) { man("b" => %w[c d]) }
      let(:c) { man("c" => %w[   ]) }
      let(:d) { man("d" => %w[   ]) }

      let(:e) { man("e" => %w[f g]) }
      let(:f) { man("f" => %w[g h]) }
      let(:g) { man("g" => %w[   ]) }
      let(:h) { man("h" => %w[   ]) }

      let(:set) { described_class.new([a, b, c, d, e, f, g, h]) }

      it "should not do anything when given no names" do
        set.deep_strip!([])

        expect(set.to_a).to match_array( [a, b, c, d, e, f, g, h] )
      end

      it "should remove just the named elements if they have no dependencies" do
        set.deep_strip!(["c", "h"])

        expect(set.to_a).to match_array( [a, b, d, e, f, g] )
      end

      it "should remove the named elements and all their dependencies" do
        set.deep_strip!(["b"])

        expect(set.to_a).to match_array( [a, e, f, g, h] )
      end

      it "should remove an entire tree of dependencies" do
        set.deep_strip!(["e"])

        expect(set.to_a).to match_array( [a, b, c, d] )
      end

      it "should allow removing all the elements" do
        set.deep_strip!(["a", "e"])

        expect(set.to_a).to match_array( [] )
      end
    end

    describe "#deep_keep!" do
      def man(o)
        k, v = o.keys.first, o.values.first
        double(k, :name => k, :dependencies => deps(v))
      end

      def deps(names)
        names.map{|n| double(:name => n)}
      end

      let(:a) { man("a" => %w[b c]) }
      let(:b) { man("b" => %w[c d]) }
      let(:c) { man("c" => %w[   ]) }
      let(:d) { man("d" => %w[   ]) }

      let(:e) { man("e" => %w[f g]) }
      let(:f) { man("f" => %w[g h]) }
      let(:g) { man("g" => %w[   ]) }
      let(:h) { man("h" => %w[   ]) }

      let(:set) { described_class.new([a, b, c, d, e, f, g, h]) }

      it "should remove all the elements when given no names" do
        set.deep_keep!([])

        expect(set.to_a).to match_array( [] )
      end

      it "should keep just the named elements if they have no dependencies" do
        set.deep_keep!(["c", "h"])

        expect(set.to_a).to match_array( [c, h] )
      end

      it "should keep the named elements and all their dependencies" do
        set.deep_keep!(["b"])

        expect(set.to_a).to match_array( [b, c, d] )
      end

      it "should keep an entire tree of dependencies" do
        set.deep_keep!(["e"])

        expect(set.to_a).to match_array( [e, f, g, h] )
      end

      it "should allow keeping all the elements" do
        set.deep_keep!(["a", "e"])

        expect(set.to_a).to match_array( [a, b, c, d, e, f, g, h] )
      end
    end

  end
end
