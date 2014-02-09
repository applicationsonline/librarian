require "fileutils"
require "pathname"
require "securerandom"

require "librarian/posix"

require "librarian/source/git/repository"

require "librarian/mock/environment"

require "support/project_path_macro"

describe Librarian::Source::Git::Repository do
  include Support::ProjectPathMacro

  let(:env) { Librarian::Mock::Environment.new }

  let(:tmp_path) { project_path + "tmp/spec/functional/source/git/repository" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }
  let(:git_source_path) { tmp_path + SecureRandom.hex(16) }
  let(:branch) { "the-branch" }
  let(:tag) { "the-tag" }
  let(:atag) { "the-atag" }

  def cmd!(command)
    Librarian::Posix.run! command
  end

  def git!(command)
    cmd!([described_class.bin] + command)
  end

  before do
    git_source_path.mkpath
    Dir.chdir(git_source_path) do
      git! %W[init]
      git! %W[config user.name Simba]
      git! %W[config user.email simba@savannah-pride.gov]

      # master
      FileUtils.touch "butter.txt"
      git! %W[add butter.txt]
      git! %W[commit -m #{"Initial Commit"}]

      # branch
      git! %W[checkout -b #{branch} --quiet]
      FileUtils.touch "jam.txt"
      git! %W[add jam.txt]
      git! %W[commit -m #{"Branch Commit"}]
      git! %W[checkout master --quiet]

      # tag/atag
      git! %W[checkout -b deletable --quiet]
      FileUtils.touch "jelly.txt"
      git! %W[add jelly.txt]
      git! %W[commit -m #{"Tag Commit"}]
      git! %W[tag #{tag}]
      git! %W[tag -am #{"Annotated Tag Commit"} #{atag}]
      git! %W[checkout master --quiet]
      git! %W[branch -D deletable]
    end
  end

  describe ".bin" do
    specify { expect(described_class.bin).to_not be_empty }
  end

  describe ".git_version" do
    specify { expect(described_class.git_version).to match( /^\d+(\.\d+)+$/ ) }
  end

  context "the original" do
    subject { described_class.new(env, git_source_path) }

    it "should recognize it" do
      expect(subject).to be_git
    end

    it "should not list any remotes for it" do
      expect(subject.remote_names).to be_empty
    end

    it "should not list any remote branches for it" do
      expect(subject.remote_branch_names).to be_empty
    end

    it "should have divergent shas for master, branch, tag, and atag" do
      revs = %W[ master #{branch} #{tag} #{atag} ]
      rev_parse = proc{|rev| git!(%W[rev-parse #{rev} --quiet]).strip}
      shas = Dir.chdir(git_source_path){revs.map(&rev_parse)}
      expect(shas.map(&:class).uniq).to eq [String]
      expect(shas.map(&:size).uniq).to eq [40]
      expect(shas.uniq).to eq shas
    end
  end

  context "a clone" do
    let(:git_clone_path) { tmp_path + SecureRandom.hex(16) }
    subject { described_class.clone!(env, git_clone_path, git_source_path) }

    let(:master_sha) { subject.hash_from("origin", "master") }
    let(:branch_sha) { subject.hash_from("origin", branch) }
    let(:tag_sha) { subject.hash_from("origin", tag) }
    let(:atag_sha) { subject.hash_from("origin", atag) }

    it "should recognize it" do
      expect(subject).to be_git
    end

    it "should have a single remote for it" do
      expect(subject).to have(1).remote_names
    end

    it "should have a remote with the expected name" do
      expect(subject.remote_names.first).to eq "origin"
    end

    it "should have the remote branch" do
      expect(subject.remote_branch_names["origin"]).to include branch
    end

    it "should be checked out on the master" do
      expect(subject).to be_checked_out(master_sha)
    end

    context "checking for commits" do
      it "has the master commit" do
        expect(subject).to have_commit(master_sha)
      end

      it "has the branch commit" do
        expect(subject).to have_commit(branch_sha)
      end

      it "has the tag commit" do
        expect(subject).to have_commit(tag_sha)
      end

      it "has the atag commit" do
        expect(subject).to have_commit(atag_sha)
      end

      it "does not have a made-up commit" do
        expect(subject).to_not have_commit(SecureRandom.hex(20))
      end

      it "does not have a tree commit" do
        master_tree_sha = Dir.chdir(git_source_path) do
          git!(%W[log -1 --no-color --format=tformat:%T master]).strip
        end
        expect(master_tree_sha).to match(/\A[0-9a-f]{40}\z/) # sanity
        expect(subject).to_not have_commit(master_tree_sha)
      end
    end

    context "checking out the branch" do
      before do
        subject.checkout! branch
      end

      it "should be checked out on the branch" do
        expect(subject).to be_checked_out(branch_sha)
      end

      it "should not be checked out on the master" do
        expect(subject).to_not be_checked_out(master_sha)
      end
    end

    context "checking out the tag" do
      before do
        subject.checkout! tag
      end

      it "should be checked out on the tag" do
        expect(subject).to be_checked_out(tag_sha)
      end

      it "should not be checked out on the master" do
        expect(subject).to_not be_checked_out(master_sha)
      end
    end

    context "checking out the annotated tag" do
      before do
        subject.checkout! atag
      end

      it "should be checked out on the annotated tag" do
        expect(subject).to be_checked_out(atag_sha)
      end

      it "should not be checked out on the master" do
        expect(subject).to_not be_checked_out(master_sha)
      end
    end
  end

end
