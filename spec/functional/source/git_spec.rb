require "fileutils"
require "pathname"
require "securerandom"

require "librarian/error"
require "librarian/posix"
require "librarian/source/git"
require "librarian/source/git/repository"
require "librarian/mock/environment"

require "support/project_path_macro"

describe Librarian::Source::Git do
  include Support::ProjectPathMacro

  let(:tmp_path) { project_path + "tmp/spec/functional/source/git" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }
  let(:env_project_path) { tmp_path + "project" }

  def cmd!(command)
    Librarian::Posix.run! command
  end

  def git!(command)
    cmd!([Librarian::Source::Git::Repository.bin] + command)
  end

  def new_env
    Librarian::Mock::Environment.new(:project_path => env_project_path)
  end

  context "when the remote is bad" do
    let(:remote) { tmp_path.join(SecureRandom.hex(8)).to_s }
    let(:env) { new_env }
    let(:source) { described_class.new(env, remote, {}) }

    it "fails when caching" do
      expect { source.cache! }.to raise_error Librarian::Error,
        /^fatal: repository .+ does not exist$/ # from git
    end
  end

  context "when the remote has a repo" do
    let(:remote) { tmp_path.join(SecureRandom.hex(8)).to_s }
    let(:git_source_path) { Pathname.new(remote) }
    let(:env) { new_env }
    let(:source) { described_class.new(env, remote, {}) }

    before do
      git_source_path.mkpath
      Dir.chdir(git_source_path) do
        git! %W[init]
        git! %W[config user.name Simba]
        git! %W[config user.email simba@savannah-pride.gov]
        FileUtils.touch "butter.txt"
        git! %W[add butter.txt]
        git! %W[commit -m #{"Initial Commit"}]
      end
    end

    let(:sha) do
      Dir.chdir(git_source_path) do
        git!(%W[rev-parse master]).strip
      end
    end

    context "when caching once" do
      it "has the expected sha" do
        expect{source.cache!}.to change{source.sha}.from(nil).to(sha)
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(9)
      end
    end

    context "when caching twice" do
      before { source.cache! }

      it "keeps the expected sha" do
        expect{source.cache!}.to_not change{source.sha}
      end

      it "runs git commands once" do
        expect{source.cache!}.to_not change{source.git_ops_count}
      end
    end

    context "when caching twice from different sources" do
      let(:other_source) { described_class.new(env, remote, {}) }
      before { other_source.cache! }

      it "has the expected sha" do
        expect{source.cache!}.to change{source.sha}.from(nil).to(sha)
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(1)
      end
    end

    context "when caching twice from different sources, second time with sha" do
      let(:other_source) { described_class.new(env, remote, {}) }
      before { other_source.cache! }

      let(:source) { described_class.new(env, remote, {:sha => sha}) }

      it "has the expected sha" do
        expect{source.cache!}.to_not change{source.sha}
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(1)
      end
    end

    context "when caching twice from different environments" do
      let(:other_source) { described_class.new(new_env, remote, {}) }
      before { other_source.cache! }

      it "has the expected sha" do
        expect{source.cache!}.to change{source.sha}.from(nil).to(sha)
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(8)
      end
    end

    context "when caching twice from different environments, second time with sha" do
      let(:other_source) { described_class.new(new_env, remote, {}) }
      before { other_source.cache! }

      let(:source) { described_class.new(env, remote, {:sha => sha}) }

      it "has the expected sha" do
        expect{source.cache!}.to_not change{source.sha}
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(3)
      end
    end

    context "when the sha is missing from a cached repo" do
      let(:other_source) { described_class.new(new_env, remote, {}) }
      before { other_source.cache! }

      before do
        Dir.chdir(git_source_path) do
          FileUtils.touch "jam.txt"
          git! %w[add jam.txt]
          git! %W[commit -m #{"Some Jam"}]
        end
      end

      let(:source) { described_class.new(env, remote, {:sha => sha}) }

      it "has a new remote sha" do
        expect(sha).to_not eq(other_source.sha)
      end

      it "has the expected sha" do
        expect{source.cache!}.to_not change{source.sha}
      end

      it "records the history" do
        expect{source.cache!}.to change{source.git_ops_count}.from(0).to(8)
      end
    end

  end

end
