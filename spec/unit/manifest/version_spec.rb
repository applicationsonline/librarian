require "librarian/manifest"

describe Librarian::Manifest::Version do

  describe "#inspect" do
    subject(:version) { described_class.new("3.2.1") }

    specify { expect(version.inspect).to eq "#<Librarian::Manifest::Version 3.2.1>" }
  end

end
