require "librarian/dependency"

describe Librarian::Dependency do

  describe "validations" do

    context "when the name is blank" do
      it "raises" do
        expect { described_class.new("", [], nil) }.
          to raise_error(ArgumentError, %{name ("") must be sensible})
      end
    end

    context "when the name has leading whitespace" do
      it "raises" do
        expect { described_class.new("  the-name", [], nil) }.
          to raise_error(ArgumentError, %{name ("  the-name") must be sensible})
      end
    end

    context "when the name has trailing whitespace" do
      it "raises" do
        expect { described_class.new("the-name  ", [], nil) }.
          to raise_error(ArgumentError, %{name ("the-name  ") must be sensible})
      end
    end

    context "when the name is a single character" do
      it "passes" do
        described_class.new("R", [], nil)
      end
    end

  end

  describe "#consistent_with?" do
    def req(s) described_class::Requirement.new(s) end
    def self.assert_consistent(a, b)
      /^(.+):(\d+):in `(.+)'$/ =~ caller.first
      line = $2.to_i

      title = "is consistent with #{a.inspect} and #{b.inspect}"
      module_eval <<-CODE, __FILE__, line
        it #{title.inspect} do
          a, b = req(#{a.inspect}), req(#{b.inspect})
          expect(a).to be_consistent_with(b)
          expect(a).to_not be_inconsistent_with(b)
          expect(b).to be_consistent_with(a)
          expect(b).to_not be_inconsistent_with(a)
        end
      CODE
    end
    def self.refute_consistent(a, b)
      /^(.+):(\d+):in `(.+)'$/ =~ caller.first
      line = $2.to_i

      title = "is inconsistent with #{a.inspect} and #{b.inspect}"
      module_eval <<-CODE, __FILE__, line
        it #{title.inspect} do
          a, b = req(#{a.inspect}), req(#{b.inspect})
          expect(a).to_not be_consistent_with(b)
          expect(a).to be_inconsistent_with(b)
          expect(b).to_not be_consistent_with(a)
          expect(b).to be_inconsistent_with(a)
        end
      CODE
    end

    # = =
    assert_consistent "3", "3"
    refute_consistent "3", "4"
    refute_consistent "3", "0"
    refute_consistent "0", "3"

    # = !=
    assert_consistent "3", "!= 4"
    assert_consistent "3", "!= 0"
    refute_consistent "3", "!= 3"

    # = >
    assert_consistent "3", "> 2"
    refute_consistent "3", "> 3"
    refute_consistent "3", "> 4"

    # = <
    assert_consistent "3", "< 4"
    refute_consistent "3", "< 3"
    refute_consistent "3", "< 2"

    # = >=
    assert_consistent "3", ">= 2"
    assert_consistent "3", ">= 3"
    refute_consistent "3", ">= 4"

    # = <=
    assert_consistent "3", "<= 4"
    assert_consistent "3", "<= 3"
    refute_consistent "3", "<= 2"

    # = ~>
    assert_consistent "3.4.1", "~> 3.4.1"
    assert_consistent "3.4.2", "~> 3.4.1"
    refute_consistent "3.4",   "~> 3.4.1"
    refute_consistent "3.5",   "~> 3.4.1"

    # != !=
    assert_consistent "!= 3", "!= 3"
    assert_consistent "!= 3", "!= 4"

    # != >
    assert_consistent "!= 3", "> 2"
    assert_consistent "!= 3", "> 3"
    assert_consistent "!= 3", "> 4"

    # != <
    assert_consistent "!= 3", "< 2"
    assert_consistent "!= 3", "< 3"
    assert_consistent "!= 3", "< 4"

    # != >=
    assert_consistent "!= 3", ">= 2"
    assert_consistent "!= 3", ">= 3"
    assert_consistent "!= 3", ">= 4"

    # != <=
    assert_consistent "!= 3", "<= 2"
    assert_consistent "!= 3", "<= 3"
    assert_consistent "!= 3", "<= 4"

    # != ~>
    assert_consistent "!= 3.4.1", "~> 3.4.1"
    assert_consistent "!= 3.4.2", "~> 3.4.1"
    assert_consistent "!= 3.5",   "~> 3.4.1"

    # > >
    assert_consistent "> 3", "> 2"
    assert_consistent "> 3", "> 3"
    assert_consistent "> 3", "> 4"

    # > <
    assert_consistent "> 3", "< 4"
    refute_consistent "> 3", "< 3"
    refute_consistent "> 3", "< 2"

    # > >=
    assert_consistent "> 3", ">= 2"
    assert_consistent "> 3", ">= 3"
    assert_consistent "> 3", ">= 4"

    # > <=
    assert_consistent "> 3", "<= 4"
    refute_consistent "> 3", "<= 3"
    refute_consistent "> 3", "<= 2"

    # > ~>
    assert_consistent "> 3.3",   "~> 3.4.1"
    assert_consistent "> 3.4.1", "~> 3.4.1"
    assert_consistent "> 3.4.2", "~> 3.4.1"
    refute_consistent "> 3.5",   "~> 3.4.1"

    # < <
    assert_consistent "< 3", "< 2"
    assert_consistent "< 3", "< 3"
    assert_consistent "< 3", "< 4"

    # < >=
    assert_consistent "< 3", ">= 2"
    refute_consistent "< 3", ">= 3"
    refute_consistent "< 3", ">= 4"

    # < <=
    assert_consistent "< 3", "<= 2"
    assert_consistent "< 3", "<= 3"
    assert_consistent "< 3", "<= 4"

    # >= >=
    assert_consistent ">= 3", ">= 2"
    assert_consistent ">= 3", ">= 3"
    assert_consistent ">= 3", ">= 4"

    # >= <=
    assert_consistent ">= 3", "<= 4"
    assert_consistent ">= 3", "<= 3"
    refute_consistent ">= 3", "<= 2"

    # >= ~>
    assert_consistent ">= 3.3",   "~> 3.4.1"
    assert_consistent ">= 3.4.1", "~> 3.4.1"
    assert_consistent ">= 3.4.2", "~> 3.4.1"
    refute_consistent ">= 3.5",   "~> 3.4.1"

    # <= <=
    assert_consistent "<= 3", "<= 2"
    assert_consistent "<= 3", "<= 3"
    assert_consistent "<= 3", "<= 4"

    # <= ~>
    assert_consistent "<= 3.5",   "~> 3.4.1"
    assert_consistent "<= 3.4.1", "~> 3.4.1"
    assert_consistent "<= 3.4.2", "~> 3.4.1"
    refute_consistent "<= 3.3",   "~> 3.4.1"

    # ~> ~>
    assert_consistent "~> 3.4.1", "~> 3.4.1"
    assert_consistent "~> 3.4.2", "~> 3.4.1"
    assert_consistent "~> 3.3",   "~> 3.4.1"
    refute_consistent "~> 3.3.3", "~> 3.4.1"
    refute_consistent "~> 3.5",   "~> 3.4.1"
    refute_consistent "~> 3.5.4", "~> 3.4.1"
  end

end
