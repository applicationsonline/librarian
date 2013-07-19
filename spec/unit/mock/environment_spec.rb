require "librarian/mock/environment"

module Librarian::Mock
  describe Environment do

    let(:env) { described_class.new }

    describe "#adapter_module" do
      specify { env.adapter_module.should be Librarian::Mock }
    end

    describe "#adapter_name" do
      specify { env.adapter_name.should be == "mock" }
    end

  end
end
