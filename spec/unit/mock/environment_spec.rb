require "librarian/mock/environment"

module Librarian::Mock
  describe Environment do

    let(:env) { described_class.new }

    describe "#version" do
      specify { env.version.should be == Librarian::VERSION }
    end

    describe "#adapter_module" do
      specify { env.adapter_module.should be Librarian::Mock }
    end

    describe "#adapter_name" do
      specify { env.adapter_name.should be == "mock" }
    end

    describe "#adapter_version" do
      specify { env.adapter_version.should be == Librarian::Mock::VERSION }
    end

  end
end
