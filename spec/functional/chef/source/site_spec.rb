require 'pathname'
require 'json'
require 'webmock'

require 'librarian'
require 'librarian/helpers'
require 'librarian/chef'
require 'librarian/linter/source_linter'

module Librarian
  module Chef
    module Source
      describe Site do

        include WebMock::API

        let(:project_path) do
          project_path = Pathname.new(__FILE__).expand_path
          project_path = project_path.dirname until project_path.join("Rakefile").exist?
          project_path
        end
        let(:tmp_path) { project_path.join("tmp/spec/functional/chef/source/site") }
        after { tmp_path.rmtree if tmp_path && tmp_path.exist? }
        let(:sample_path) { tmp_path.join("sample") }
        let(:sample_metadata) do
          Helpers.strip_heredoc(<<-METADATA)
            version "0.6.5"
          METADATA
        end

        let(:api_url) { "http://site.cookbooks.com" }

        let(:sample_index_data) do
          {
            "name" => "sample",
            "versions" => [
              "#{api_url}/cookbooks/sample/versions/0_6_5"
            ]
          }
        end
        let(:sample_0_6_5_data) do
          {
            "version" => "0.6.5",
            "file" => "#{api_url}/cookbooks/sample/versions/0_6_5/file.tar.gz"
          }
        end
        let(:sample_0_6_5_package) do
          s = StringIO.new
          z = Zlib::GzipWriter.new(s, Zlib::NO_COMPRESSION)
          t = Archive::Tar::Minitar::Output.new(z)
          t.tar.add_file_simple("sample/metadata.rb", :mode => 0700,
            :size => sample_metadata.bytesize){|io| io.write(sample_metadata)}
          t.close
          z.close unless z.closed?
          s.string
        end

        # depends on repo_path being defined in each context
        let(:env) { Environment.new(:project_path => repo_path) }

        before do
          stub_request(:get, "#{api_url}/cookbooks/sample").
            to_return(:body => JSON.dump(sample_index_data))

          stub_request(:get, "#{api_url}/cookbooks/sample/versions/0_6_5").
            to_return(:body => JSON.dump(sample_0_6_5_data))

          stub_request(:get, "#{api_url}/cookbooks/sample/versions/0_6_5/file.tar.gz").
            to_return(:body => sample_0_6_5_package)
        end

        after do
          WebMock.reset!
        end

        let(:repo_path) { tmp_path.join("methods") }
        before { repo_path.mkpath }

        describe "lint" do
          it "lints" do
            Librarian::Linter::SourceLinter.lint! described_class
          end
        end

        describe "class methods" do

          describe ".lock_name" do
            specify { described_class.lock_name.should == "SITE" }
          end

          describe ".from_spec_args" do
            it "gives the expected source" do
              args = { }
              source = described_class.from_spec_args(env, api_url, args)
              source.uri.should == api_url
            end

            it "raises on unexpected args" do
              args = {:k => 3}
              expect { described_class.from_spec_args(env, api_url, args) }.
                to raise_error Librarian::Error, "unrecognized options: k"
            end
          end

          describe ".from_lock_options" do
            it "gives the expected source" do
              options = {:remote => api_url}
              source = described_class.from_lock_options(env, options)
              source.uri.should == api_url
            end

            it "roundtrips" do
              options = {:remote => api_url}
              source = described_class.from_lock_options(env, options)
              source.to_lock_options.should == options
            end
          end

        end

        describe "instance methods" do
          let(:source) { described_class.new(env, api_url) }

          describe "#manifests" do
            it "gives a list of all manifests" do
              manifests = source.manifests("sample")
              manifests.should have(1).item
              manifest = manifests.first
              manifest.source.should be source
              manifest.version.should == Manifest::Version.new("0.6.5")
              manifest.dependencies.should be_empty
            end
          end

          describe "#fetch_version" do
            it "fetches the version based on extra" do
              extra = "#{api_url}/cookbooks/sample/versions/0_6_5"
              source.fetch_version("sample", extra).should == "0.6.5"
            end
          end

          describe "#fetch_dependencies" do
            it "fetches the dependencies based on extra" do
              extra = "#{api_url}/cookbooks/sample/versions/0_6_5"
              source.fetch_dependencies("sample", "0.6.5", extra).should == [ ]
            end
          end

          describe "#pinned?" do
            it "returns false" do
              source.should_not be_pinned
            end
          end

          describe "#unpin!" do
            it "is a no-op" do
              source.unpin!
            end
          end

          describe "#install!" do
            before { env.install_path.mkpath }

            context "directly" do
              it "installs the manifest" do
                manifest = Manifest.new(source, "sample")
                manifest.version = "0.6.5"
                source.install!(manifest)
                text = env.install_path.join("sample/metadata.rb").read
                text.should == sample_metadata
              end
            end

            context "indirectly" do
              it "installs the manifest" do
                manifest = source.manifests("sample").first
                source.install!(manifest)
                text = env.install_path.join("sample/metadata.rb").read
                text.should == sample_metadata
              end
            end
          end

          describe "#to_spec_args" do
            it "gives the expected spec args" do
              source.to_spec_args.should == [api_url, { }]
            end
          end

          describe "#to_lock_options" do
            it "gives the expected lock options" do
              source.to_lock_options.should == {:remote => api_url}
            end

            it "roundtrips" do
              options = source.to_lock_options
              described_class.from_lock_options(env, options).should == source
            end
          end

        end

      end
    end
  end
end
