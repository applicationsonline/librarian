require "librarian/environment"

module Librarian
  describe Environment do

    let(:env) { described_class.new }

    describe "#ensure!" do
      it "should delegate to Action::Ensure" do
        action = mock
        Action::Ensure.stub(:new) { action }

        action.should_receive(:run)

        env.ensure!
      end
    end

    describe "#clean!" do
      it "should delegate to Action::Clean" do
        action = mock
        Action::Clean.stub(:new) { action }

        action.should_receive(:run)

        env.clean!
      end
    end

    describe "#install!" do
      it "should delegate to Action::Install" do
        env.stub(:resolve!)

        action = mock
        Action::Install.stub(:new) { action }

        action.should_receive(:run)

        env.install!
      end
    end

  end
end
