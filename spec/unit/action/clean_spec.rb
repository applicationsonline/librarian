require "librarian/action/clean"

module Librarian
  describe Action::Clean do

    let(:env) { double }
    let(:action) { described_class.new(env) }

    before do
      action.stub(:debug)
    end

    describe "#run" do

      describe "behavior" do

        after do
          action.run
        end

        describe "clearing the cache path" do

          before do
            action.stub(:clean_install_path)
          end

          context "when the cache path is missing" do
            before do
              env.stub_chain(:cache_path, :exist?) { false }
            end

            it "should not try to clear the cache path" do
              expect(env.cache_path).to receive(:rmtree).never
            end
          end

          context "when the cache path is present" do
            before do
              env.stub_chain(:cache_path, :exist?) { true }
            end

            it "should try to clear the cache path" do
              expect(env.cache_path).to receive(:rmtree).exactly(:once)
            end
          end

        end

        describe "clearing the install path" do

          before do
            action.stub(:clean_cache_path)
          end

          context "when the install path is missing" do
            before do
              env.stub_chain(:install_path, :exist?) { false }
            end

            it "should not try to clear the install path" do
              expect(env.install_path).to receive(:children).never
            end
          end

          context "when the install path is present" do
            before do
              env.stub_chain(:install_path, :exist?) { true }
            end

            it "should try to clear the install path" do
              children = [double, double, double]
              children.each do |child|
                child.stub(:file?) { false }
              end
              env.stub_chain(:install_path, :children) { children }

              children.each do |child|
                expect(child).to receive(:rmtree).exactly(:once)
              end
            end

            it "should only try to clear out directories from the install path, not files" do
              children = [double(:file? => false), double(:file? => true), double(:file? => true)]
              env.stub_chain(:install_path, :children) { children }

              children.select(&:file?).each do |child|
                expect(child).to receive(:rmtree).never
              end
              children.reject(&:file?).each do |child|
                expect(child).to receive(:rmtree).exactly(:once)
              end
            end
          end

        end

      end

    end

  end
end
