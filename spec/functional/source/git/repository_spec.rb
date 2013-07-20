require "fileutils"
require "pathname"
require "securerandom"

require "rugged"

require "librarian/source/git/repository"

describe Librarian::Source::Git::Repository do

  let(:env) do
    double(:ui => nil, :logger => double(:debug => nil, :info => nil))
  end

  let(:project_path) do
    project_path = Pathname.new(__FILE__).expand_path
    project_path = project_path.dirname until project_path.join("Rakefile").exist?
    project_path
  end
  let(:tmp_path) { project_path + "tmp/spec/functional/source/git/repository" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }
  let(:git_source_path) { tmp_path + SecureRandom.hex(16) }
  let(:branch) { "the-branch" }
  let(:tag) { "the-tag" }
  let(:atag) { "the-atag" }

  def cmd!(command)
    out = ""
    err = ""
    thread = nil
    Open3.popen3(*command) do |i, o, e, t|
      out = o.read
      err = e.read
      thread = t
    end

    raise StandardError, err unless (thread ? thread.value : $?).success?

    out
  end

  def git!(dir, command)
    Dir.chdir(dir) { cmd!([described_class.bin] + command) }
  end

  def git_authorship(repo)
    {
      :name => repo.config["user.name"],
      :email => repo.config["user.email"],
      :time => Time.now,
    }
  end

  def git_in_branch(repo, name, source)
    repo.create_branch name, source
    git! repo.workdir, %W[checkout #{name} --quiet]
    yield
  ensure
    git! repo.workdir, %W[checkout #{source} --quiet]
  end

  def git_in_temp_branch(repo, source)
    deletable = "deletable-#{SecureRandom.hex(16)}"
    git_in_branch repo, deletable, source do
      yield deletable
    end
  ensure
    Rugged::Branch.lookup(repo, deletable).delete!
  end

  def git_add_and_commit_empty_file(repo, fn, options = { })
    message = options[:message]
    message << "\n" unless message.end_with?("\n")
    FileUtils.touch File.join(repo.workdir, fn)
    repo.index.add fn
    repo.index.write
    Rugged::Commit.create repo, {
      :tree => repo.index.write_tree,
      :message => message,
      :author => git_authorship(repo),
      :committer => git_authorship(repo),
      :parents => repo.empty? ? [] : [repo.head.target].compact,
      :update_ref => "HEAD",
    }
    nil
  end

  before do
    git_source_path.mkpath
    repo = Rugged::Repository.init_at(git_source_path.to_s)
    repo.config["user.name"] = "Simba"
    repo.config["user.email"] = "simba@savannah-pride.gov"
    git_add_and_commit_empty_file repo, "butter.txt", :message => "Initial Commit"
    git_in_branch repo, branch, "master" do
      git_add_and_commit_empty_file repo, "jam.txt", :message => "Branch Commit"
    end
    git_in_temp_branch repo, "master" do |deletable|
      git_add_and_commit_empty_file repo, "jelly.txt", :message => "Tag Commit"
      Rugged::Tag.create repo, :name => tag, :target => deletable
      Rugged::Tag.create repo, :name => atag, :target => deletable,
        :message => "Annotated Tag Object Commit", :tagger => git_authorship(repo)
    end
  end

  context "the original" do
    subject { described_class.new(env, git_source_path) }

    it "should recognize it" do
      subject.should be_git
    end

    it "should not list any remotes for it" do
      subject.remote_names.should be_empty
    end

    it "should not list any remote branches for it" do
      subject.remote_branch_names.should be_empty
    end

    it "should have divergent shas for master, branch, tag, and atag" do
      revs = %W[ master #{branch} #{tag} #{atag} ]
      shas = revs.map{|r| git!(git_source_path, %W[ rev-parse #{r} --quiet]).strip}
      shas.map(&:class).uniq.should be == [String]
      shas.map(&:size).uniq.should be == [40]
      shas.uniq.should be == shas
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
      subject.should be_git
    end

    it "should have a single remote for it" do
      subject.should have(1).remote_names
    end

    it "should have a remote with the expected name" do
      subject.remote_names.first.should == "origin"
    end

    it "should have the remote branch" do
      subject.remote_branch_names["origin"].should include branch
    end

    it "should be checked out on the master" do
      subject.should be_checked_out(master_sha)
    end

    context "checking out the branch" do
      before do
        subject.checkout! branch
      end

      it "should be checked out on the branch" do
        subject.should be_checked_out(branch_sha)
      end

      it "should not be checked out on the master" do
        subject.should_not be_checked_out(master_sha)
      end
    end

    context "checking out the tag" do
      before do
        subject.checkout! tag
      end

      it "should be checked out on the tag" do
        subject.should be_checked_out(tag_sha)
      end

      it "should not be checked out on the master" do
        subject.should_not be_checked_out(master_sha)
      end
    end

    context "checking out the annotated tag" do
      before do
        subject.checkout! atag
      end

      it "should be checked out on the annotated tag" do
        subject.should be_checked_out(atag_sha)
      end

      it "should not be checked out on the master" do
        subject.should_not be_checked_out(master_sha)
      end
    end
  end

end
