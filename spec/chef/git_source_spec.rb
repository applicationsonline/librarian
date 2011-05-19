require 'pathname'
require 'securerandom'

require 'librarian'
require 'librarian/helpers'
require 'librarian/chef'

module Librarian
  module Chef
    module Source
      describe Git do

        project_path = Pathname.new(__FILE__).expand_path
        project_path = project_path.dirname until project_path.join("Rakefile").exist?
        tmp_path = project_path.join("tmp/spec/chef/git-source")
        sample_path = tmp_path.join('sample')
        sample_metadata = Helpers.strip_heredoc(<<-METADATA)
          version '0.6.5'
        METADATA

        before :all do
          sample_path.rmtree if sample_path.exist?
          sample_path.mkpath
          sample_path.join('metadata.rb').open('wb') { |f| f.write(sample_metadata) }
          Dir.chdir(sample_path) do
            `git init`
            `git add metadata.rb`
            `git commit -m "Initial commit."`
          end
        end

        context "a single dependency with a git source" do

          it "should resolve" do
            repo_path = tmp_path.join('repo/resolve')
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join('cookbooks').mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join('Cheffile').open('wb') { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.resolve!
            repo_path.join('Cheffile.lock').should be_exist
            repo_path.join('cookbooks/sample').should_not be_exist
          end

          it "should install" do
            repo_path = tmp_path.join('repo/install')
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join('cookbooks').mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join('Cheffile').open('wb') { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.install!
            repo_path.join('Cheffile.lock').should be_exist
            repo_path.join('cookbooks/sample').should be_exist
            repo_path.join('cookbooks/sample/metadata.rb').should be_exist
          end

          it "should resolve and separately install" do
            repo_path = tmp_path.join('repo/resolve-install')
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join('cookbooks').mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :git => #{sample_path.to_s.inspect}
            CHEFFILE
            repo_path.join('Cheffile').open('wb') { |f| f.write(cheffile) }
            Chef.stub!(:project_path) { repo_path }

            Chef.resolve!
            repo_path.join('tmp').rmtree if repo_path.join('tmp').exist?
            Chef.install!
            repo_path.join('cookbooks/sample').should be_exist
            repo_path.join('cookbooks/sample/metadata.rb').should be_exist
          end

        end

      end
    end
  end
end
