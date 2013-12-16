require "librarian/dependency"

describe Librarian::Dependency::Requirement do

  describe "#inspect" do
    subject(:requirement) { described_class.new(">= 3.2.1") }

    specify { expect(requirement.inspect).
      to eq "#<Librarian::Dependency::Requirement >= 3.2.1>" }
  end

end
