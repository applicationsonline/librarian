require "librarian/mock/environment"

module Librarian::Mock
  describe Environment do

    let(:env) { described_class.new }

    describe "#version" do
      specify { expect(env.version).to eq Librarian::VERSION }
    end

    describe "#adapter_module" do
      specify { expect(env.adapter_module).to eq Librarian::Mock }
    end

    describe "#adapter_name" do
      specify { expect(env.adapter_name).to eq "mock" }
    end

    describe "#adapter_version" do
      specify { expect(env.adapter_version).to eq Librarian::Mock::VERSION }
    end

  end
end
