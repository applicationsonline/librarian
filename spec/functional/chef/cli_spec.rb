require "securerandom"

require "support/cli_macro"

require "librarian/chef/cli"

module Librarian
  module Chef
    describe Cli do
      include CliMacro

      describe "init" do
        before do
          cli! "init"
        end

        it "should create a file named Cheffile" do
          pwd.should have_file "Cheffile"
        end
      end

      describe "version" do
        before do
          cli! "version"
        end

        it "should print the version" do
          stdout.should == strip_heredoc(<<-STDOUT)
            librarian-#{VERSION}
          STDOUT
        end
      end

      describe "install" do

        context "a simple Cheffile with one cookbook" do
          let(:metadata) { {
            "name" => "apt",
            "version" => "1.0.0",
            "dependencies" => { },
          } }

          before do
            write_json_file! "cookbook-sources/apt/metadata.json", metadata
            write_file! "Cheffile", strip_heredoc(<<-CHEFFILE)
              cookbook 'apt',
                :path => 'cookbook-sources'
            CHEFFILE

            cli! "install"
          end

          it "should write a lockfile" do
            pwd.should have_file "Cheffile.lock"
          end

          it "should install the cookbook" do
            pwd.should have_json_file "cookbooks/apt/metadata.json", metadata
          end
        end

        context "a simple Cheffile with one cookbook with one dependency" do
          let(:main_metadata) { {
            "name" => "main",
            "version" => "1.0.0",
            "dependencies" => {
              "sub" => "1.0.0",
            }
          } }
          let(:sub_metadata) { {
            "name" => "sub",
            "version" => "1.0.0",
            "dependencies" => { },
          } }

          before do
            write_json_file! "cookbook-sources/main/metadata.json", main_metadata
            write_json_file! "cookbook-sources/sub/metadata.json", sub_metadata
            write_file! "Cheffile", strip_heredoc(<<-CHEFFILE)
              path 'cookbook-sources'
              cookbook 'main'
            CHEFFILE

            cli! "install"
          end

          it "should write a lockfile" do
            pwd.should have_file "Cheffile.lock"
          end

          it "should install the dependant cookbook" do
            pwd.should have_json_file "cookbooks/main/metadata.json", main_metadata
          end

          it "should install the independent cookbook" do
            pwd.should have_json_file "cookbooks/sub/metadata.json", sub_metadata
          end
        end

      end

    end
  end
end
