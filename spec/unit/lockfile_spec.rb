require 'librarian'
require 'librarian/mock'

module Librarian
  describe Lockfile do

    before do
      Mock.registry :clear => true do
        source 'source-1' do
          spec 'alpha', '1.1'
        end
      end
    end

    let(:spec) do
      Mock.dsl do
        src 'source-1'
        dep 'alpha', '1.1'
      end
    end

    let(:resolver) { Mock.resolver }
    let(:resolution) { resolver.resolve(spec) }

    context "sanity" do
      context "the resolution" do
        subject { resolution }

        it { should be_correct }
      end
    end

    describe "#save" do
      let(:lockfile) { Mock.ephemeral_lockfile }
      let(:lockfile_text) { lockfile.save(resolution) }

      context "just saving" do
        it "should return the lockfile text" do
          lockfile_text.should_not be_nil
        end
      end

      context "bouncing" do
        let(:bounced_resolution) { lockfile.load(lockfile_text) }
        let(:bounced_lockfile_text) { lockfile.save(bounced_resolution) }

        it "should return the same lockfile text after bouncing as before bouncing" do
          bounced_lockfile_text.should == lockfile_text
        end
      end
    end

  end
end
