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

          it "should resolve" do
            repo_path = tmp_path.join("repo/resolve")
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.resolve!
            repo_path.join("Cheffile.lock").should be_exist
            repo_path.join("cookbooks/sample").should_not be_exist
          end

          it "should install" do
            repo_path = tmp_path.join("repo/install")
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.install!
            repo_path.join("Cheffile.lock").should be_exist
            repo_path.join("cookbooks/sample").should be_exist
            repo_path.join("cookbooks/sample/metadata.rb").should be_exist
          end

          it "should resolve and separately install" do
            repo_path = tmp_path.join("repo/resolve-install")
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.resolve!
            repo_path.join("tmp").rmtree if repo_path.join("tmp").exist?
            Chef.install!
            repo_path.join("cookbooks/sample").should be_exist
            repo_path.join("cookbooks/sample/metadata.rb").should be_exist
          end

          it "should resolve, change, and resolve" do
            repo_path = tmp_path.join("repo/resolve-update")
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              git #{cookbooks_path.to_s.inspect}
              cookbook "first-sample"
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }
            Chef.resolve!
            repo_path.join("Cheffile.lock").should exist

            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              git #{cookbooks_path.to_s.inspect}
              cookbook "first-sample"
              cookbook "second-sample"
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }
            Chef.resolve!
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
            it "should not resolve" do
              repo_path = tmp_path.join("repo/resolve")
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join("cookbooks").mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample",
                  :git => #{git_path.to_s.inspect}
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
              Chef.stub!(:project_path) { repo_path }

              expect{ Chef.resolve! }.to raise_error
            end
          end

          context "if the path option is wrong" do
            it "should not resolve" do
              repo_path = tmp_path.join("repo/resolve")
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
              Chef.stub!(:project_path) { repo_path }

              expect{ Chef.resolve! }.to raise_error
            end
          end

          context "if the path option is right" do
            it "should not resolve" do
              repo_path = tmp_path.join('repo/resolve')
              repo_path.rmtree if repo_path.exist?
              repo_path.mkpath
              repo_path.join('cookbooks').mkpath
              cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
                #!/usr/bin/env ruby
                cookbook "sample",
                  :git => #{git_path.to_s.inspect},
                  :path => "buttercup"
              CHEFFILE
              repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
              Chef.stub!(:project_path) { repo_path }

              Chef.resolve!
              repo_path.join("Cheffile.lock").should be_exist
              repo_path.join("cookbooks/sample").should_not be_exist
            end
          end

        end

        context "missing a metadata" do
          let(:git_path) { tmp_path.join("big-git-repo") }

          it "should explain the problem" do
            repo_path = tmp_path.join("repo/resolve")
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join("cookbooks").mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              cookbook "sample",
                :git => #{git_path.to_s.inspect}
            CHEFFILE
            repo_path.join("Cheffile").open("wb") { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            expect { Chef.resolve! }.
              to raise_error(Librarian::Error, /no metadata file found/i)
            repo_path.join("Cheffile.lock").should_not be_exist
            repo_path.join("cookbooks/sample").should_not be_exist
          end
        end

      end
    end
  end
end
