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

    describe "#install_consistent_resolution!" do

      before do
        env.stub(:specfile_name) { "Specfile" }
        env.stub(:lockfile_name) { "Specfile.lock" }
      end

      context "if the specfile is missing" do
        before do
          env.stub_chain(:specfile_path, :exist?) { false }
        end

        it "should raise an error" do
          expect { env.install_consistent_resolution! }.to raise_error(Error)
        end

        it "should raise an error describing that the specfile is missing" do
          expect { env.install_consistent_resolution! }.to raise_error(Error, "Specfile missing!")
        end
      end

      context "if the specfile is present but the lockfile is missing" do
        before do
          env.stub_chain(:specfile_path, :exist?) { true }
          env.stub_chain(:lockfile_path, :exist?) { false }
        end

        it "should raise an error" do
          expect { env.install_consistent_resolution! }.to raise_error(Error)
        end

        it "should raise an error describing that the lockfile is missing" do
          expect { env.install_consistent_resolution! }.to raise_error(Error, "Specfile.lock missing!")
        end
      end

      context "if the specfile and lockfile are present but out of sync" do
        before do
          env.stub_chain(:specfile_path, :exist?) { true }
          env.stub_chain(:lockfile_path, :exist?) { true }
          env.stub_chain(:spec_consistent_with_lock?) { false }
        end

        it "should raise an error" do
          expect { env.install_consistent_resolution! }.to raise_error(Error)
        end

        it "should raise an error describing that the specfile and lockfile are inconsistent" do
          expect { env.install_consistent_resolution! }.to raise_error(Error, "Specfile and Specfile.lock are out of sync!")
        end
      end

      context "if the specfile and lockfile are present and in sync" do
        before do
          env.stub_chain(:specfile_path, :exist?) { true }
          env.stub_chain(:lockfile_path, :exist?) { true }
          env.stub_chain(:spec_consistent_with_lock?) { true }
        end

        it "should not raise an error" do
          env.stub_chain(:lock, :manifests) { [] }

          expect { env.install_consistent_resolution! }.to_not raise_error
        end

        it "should command all the manifests to install" do
          manifests = [mock, mock, mock]
          env.stub_chain(:lock, :manifests) { manifests }

          manifests.each do |manifest|
            manifest.should_receive(:install!).exactly(:once)
          end

          env.install_consistent_resolution!
        end
      end

    end

  end
end
