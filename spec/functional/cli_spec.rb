require "securerandom"

require "librarian/rspec/support/cli_macro"

require "librarian/mock/cli"

module Librarian
  module Mock
    describe Cli do
      include Librarian::RSpec::Support::CliMacro

      describe "version" do
        before do
          cli! "version"
        end

        it "should print the version" do
          expect(stdout).to eq strip_heredoc(<<-STDOUT)
            librarian-#{Librarian::VERSION}
            librarian-mock-#{Librarian::Mock::VERSION}
          STDOUT
        end
      end

    end
  end
end
