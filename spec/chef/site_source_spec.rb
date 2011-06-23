require 'webmock'

require 'librarian'
require 'librarian/helpers'
require 'librarian/chef'

module Librarian
  module Chef
    module Source
      describe Site do

        include WebMock::API

        project_path = Pathname.new(__FILE__).expand_path
        project_path = project_path.dirname until project_path.join("Rakefile").exist?
        tmp_path = project_path.join("tmp/spec/chef/site-source")
        sample_path = tmp_path.join('sample')
        sample_metadata = Helpers.strip_heredoc(<<-METADATA)
          version '0.6.5'
        METADATA

        api_url = "http://site.cookbooks.com"

        sample_index_data = {
          "name" => "sample",
          "versions" => [
            "#{api_url}/cookbooks/sample/versions/0_6_5"
          ]
        }
        sample_0_6_5_data = {
          "version" => "0.6.5",
          "file" => "#{api_url}/cookbooks/sample/versions/0_6_5/file.tar.gz"
        }

        before :all do
          sample_path.rmtree if sample_path.exist?
          sample_path.mkpath
          sample_path.join('metadata.rb').open('wb') { |f| f.write(sample_metadata) }
          Dir.chdir(sample_path.dirname) do
            system "tar --create --gzip --file sample.tar.gz #{sample_path.basename}"
          end
        end

        before do
          stub_request(:get, "#{api_url}/cookbooks/sample").
            to_return(:body => JSON.dump(sample_index_data))

          stub_request(:get, "#{api_url}/cookbooks/sample/versions/0_6_5").
            to_return(:body => JSON.dump(sample_0_6_5_data))

          stub_request(:get, "#{api_url}/cookbooks/sample/versions/0_6_5/file.tar.gz").
            to_return(:body => sample_path.dirname.join("sample.tar.gz").read)
        end

        after do
          WebMock.reset!
        end

        context "a single dependency with a site source" do

          it "should resolve" do
            repo_path = tmp_path.join('repo/resolve')
            repo_path.rmtree if repo_path.exist?
            repo_path.mkpath
            repo_path.join('cookbooks').mkpath
            cheffile = Helpers.strip_heredoc(<<-CHEFFILE)
              #!/usr/bin/env ruby
              cookbook "sample", :site => "#{api_url}"
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
              cookbook "sample", :site => "#{api_url}"
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
              cookbook "sample", :site => "#{api_url}"
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
