require "pathname"
require "securerandom"

require "librarian/error"
require "librarian/source/git"
require "librarian/mock/environment"

describe Librarian::Source::Git do

  let(:project_path) do
    project_path = Pathname.new(__FILE__).expand_path
    project_path = project_path.dirname until project_path.join("Rakefile").exist?
    project_path
  end
  let(:tmp_path) { project_path + "tmp/spec/functional/source/git" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }
  let(:env_project_path) { tmp_path + "project" }

  context "when the remote is bad" do
    let(:remote) { tmp_path.join(SecureRandom.hex(8)).to_s }
    let(:env) { Librarian::Mock::Environment.new(:project_path => env_project_path) }
    let(:source) { described_class.new(env, remote, {}) }

    it "fails when caching" do
      expect { source.cache! }.to raise_error Librarian::Error,
        /^fatal: repository .+ does not exist$/ # from git
    end
  end

end
