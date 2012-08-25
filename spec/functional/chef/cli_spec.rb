require "securerandom"

require "support/cli_macro"

require "librarian/chef/cli"

module Librarian
  module Chef
    describe Cli do
      include CliMacro

      describe "init" do

        it "should create a file named Cheffile" do
          cli! "init"

          Dir.new(pwd).should include "Cheffile"
        end

      end

      describe "version" do

        it "should print the version" do
          cli! "version"

          stdout.should == strip_heredoc(<<-STDOUT)
            librarian-#{VERSION}
          STDOUT
        end

      end

    end
  end
end
