require "librarian/posix"

describe Librarian::Posix do

  let(:project_path) do
    project_path = Pathname.new(__FILE__).expand_path
    project_path = project_path.dirname until project_path.join("Rakefile").exist?
    project_path
  end
  let(:tmp_path) { project_path + "tmp/spec/functional/posix" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }

  describe ".run!" do

    it "returns the stdout" do
      res = described_class.run!(%w[echo hello there]).strip
      res.should be == "hello there"
    end

    it "changes directory" do
      tmp_path.mkpath
      res = described_class.run!(%w[pwd], :chdir => tmp_path).strip
      res.should be == tmp_path.to_s
    end

    it "reads the env" do
      res = described_class.run!(%w[env], :env => {"KOALA" => "BEAR"})
      line = res.lines.find{|l| l.start_with?("KOALA=")}.strip
      line.should be == "KOALA=BEAR"
    end

  end

end
