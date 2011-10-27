require 'pathname'
require 'securerandom'

require 'librarian'
require 'librarian/helpers'
require 'librarian/chef'

module Librarian
  module Chef
    module Source
      describe Git do

        let(:project_path) do
          project_path = Pathname.new(__FILE__).expand_path
          project_path = project_path.dirname until project_path.join("Rakefile").exist?
          project_path
        end
        let(:tmp_path) { project_path.join("tmp/spec/chef/git-source") }

        let(:cookbooks_path) { tmp_path.join("cookbooks") }

        # depends on repo_path being defined in each context
        let(:env) { Environment.new(:project_path => repo_path) }

        context "a single dependency with a git source" do

          let(:sample_path) { tmp_path.join("sample") }
          let(:sample_metadata) do
            Helpers.strip_heredoc(<<-METADATA)
              version "0.6.5"
            METADATA
          end

          let(:first_sample_path) { cookbooks_path.join("first-sample") }
          let(:first_sample_metadata) do
            Helpers.strip_heredoc(<<-METADATA)
              version "3.2.1"
            METADATA
          end

          let(:second_sample_path) { cookbooks_path.join("second-sample") }
          let(:second_sample_metadata) do
            Helpers.strip_heredoc(<<-METADATA)
              version "4.3.2"
            METADATA
          end

          before :all do
            sample_path.rmtree if sample_path.exist?
            sample_path.mkpath
            sample_path.join("metadata.rb").open("wb") { |f| f.write(sample_metadata) }
            Dir.chdir(sample_path) do
              `git init`
              `git add metadata.rb`
              `git commit -m "Initial commit."`
            end

            cookbooks_path.rmtree if cookbooks_path.exist?
            cookbooks_path.mkpath
            first_sample_path.mkpath
            first_sample_path.join("metadata.rb").open("wb") { |f| f.write(first_sample_metadata) }
            second_sample_path.mkpath
            second_sample_path.join("metadata.rb").open("wb") { |f| f.write(second_sample_metadata) }
            Dir.chdir(cookbooks_path) do
              `git init`
              `git add .`
              `git commit -m "Initial commit."`
            end
          end

          context "resolving" do
            let(:repo_path) { tmp_path.join("repo/resolve") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample", :git => #{sample_path.to_s.inspect}
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            context "the resolve" do
              it "should not raise an exception" do
                expect { env.resolve! }.to_not raise_error
              end
            end

            context "the results" do
              before { env.resolve! }

              it "should create the lockfile" do
                repo_path.join("Cheffile.lock").should exist
              end

              it "should not attempt to install the sample cookbok" do
                repo_path.join("cookbooks/sample").should_not exist
              end
            end
          end

          context "installing" do
            let(:repo_path) { tmp_path.join("repo/install") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample", :git => #{sample_path.to_s.inspect}
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            context "the install" do
              it "should not raise an exception" do
                expect { env.install! }.to_not raise_error
              end
            end

            context "the results" do
              before { env.install! }

              it "should create the lockfile" do
                repo_path.join("Cheffile.lock").should exist
              end

              it "should create the directory for the cookbook" do
                repo_path.join("cookbooks/sample").should exist
              end

              it "should copy the cookbook files into the cookbook directory" do
                repo_path.join("cookbooks/sample/metadata.rb").should exist
              end
            end
          end

          context "resolving and and separately installing" do
            let(:repo_path) { tmp_path.join("repo/resolve-install") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample", :git => #{sample_path.to_s.inspect}
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }

              env.resolve!
              repo_path.join("tmp").rmtree if repo_path.join("tmp").exist?
            end

            context "the install" do
              it "should not raise an exception" do
                expect { env.install! }.to_not raise_error
              end
            end

            context "the results" do
              before { env.install! }

              it "should create the directory for the cookbook" do
                repo_path.join("cookbooks/sample").should exist
              end

              it "should copy the cookbook files into the cookbook directory" do
                repo_path.join("cookbooks/sample/metadata.rb").should exist
              end
            end
          end

          context "resolving, changing, and resolving" do
            let(:repo_path) { tmp_path.join("repo/resolve-update") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                git #{cookbooks_path.to_s.inspect}
                cookbook "first-sample"
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
              env.resolve!

              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                git #{cookbooks_path.to_s.inspect}
                cookbook "first-sample"
                cookbook "second-sample"
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            context "the second resolve" do
              it "should not raise an exception" do
                expect { env.resolve! }.to_not raise_error
              end
            end
          end

        end

        context "with a path" do

          let(:git_path) { tmp_path.join("big-git-repo") }
          let(:sample_path) { git_path.join("buttercup") }
          let(:sample_metadata) do
            Helpers.strip_heredoc(<<-METADATA)
              version "0.6.5"
            METADATA
          end

          before :all do
            git_path.rmtree if git_path.exist?
            git_path.mkpath
            sample_path.mkpath
            sample_path.join("metadata.rb").open("wb") { |f| f.write(sample_metadata) }
            Dir.chdir(git_path) do
              `git init`
              `git add .`
              `git commit -m "Initial commit."`
            end
          end

          context "if no path option is given" do
            let(:repo_path) { tmp_path.join("repo/resolve") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample",
                  :git => #{git_path.to_s.inspect}
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            it "should not resolve" do
              expect{ env.resolve! }.to raise_error
            end
          end

          context "if the path option is wrong" do
            let(:repo_path) { tmp_path.join("repo/resolve") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample",
                  :git => #{git_path.to_s.inspect},
                  :path => "jelly"
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            it "should not resolve" do
              expect{ env.resolve! }.to raise_error
            end
          end

          context "if the path option is right" do
            let(:repo_path) { tmp_path.join("repo/resolve") }
            before do
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample",
                  :git => #{git_path.to_s.inspect},
                  :path => "buttercup"
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            end

            context "the resolve" do
              it "should not raise an exception" do
                expect { env.resolve! }.to_not raise_error
              end
            end

            context "the results" do
              before { env.resolve! }

              it "should create the lockfile" do
                repo_path.join("Cheffile.lock").should exist
              end
            end
          end

        end

        context "missing a metadata" do
          let(:git_path) { tmp_path.join("big-git-repo") }
          let(:repo_path) { tmp_path.join("repo/resolve") }
          before do
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              cookbook "sample",
                :git => #{git_path.to_s.inspect}
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
          end

          context "the resolve" do
            it "should raise an exception" do
              expect { env.resolve! }.to raise_error
            end

            it "should explain the problem" do
              expect { env.resolve! }.
                to raise_error(Librarian::Error, /no metadata file found/i)
            end
          end

          context "the results" do
            before { env.resolve! rescue nil }

            it "should not create the lockfile" do
              repo_path.join("Cheffile.lock").should_not exist
            end

            it "should not create the directory for the cookbook" do
              repo_path.join("cookbooks/sample").should_not exist
            end
          end
        end

      end
    end
  end
end
