require "librarian/action/base"

module Librarian
  describe Action::Base do

    let(:env) { double }
    let(:action) { described_class.new(env) }

    subject { action }

    it { should respond_to :environment }

    it "should have the environment that was assigned to it" do
      expect(action.environment).to be env
    end

  end
end
