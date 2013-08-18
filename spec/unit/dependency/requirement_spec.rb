require "librarian/dependency"

describe Librarian::Dependency::Requirement do

  describe "#inspect" do
    subject(:requirement) { described_class.new(">= 3.2.1") }

    specify { requirement.inspect.should be ==
      "#<Librarian::Dependency::Requirement >= 3.2.1>" }
  end

end
