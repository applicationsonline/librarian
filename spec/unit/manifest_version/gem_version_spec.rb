require "librarian/manifest"

describe Librarian::ManifestVersion::GemVersion do

  describe "#inspect" do
    subject(:version) { described_class.new("3.2.1") }

    specify { version.inspect.should be ==
      "#<Librarian::ManifestVersion::GemVersion 3.2.1>" }
  end

end
