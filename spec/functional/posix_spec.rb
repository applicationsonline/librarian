require "librarian/posix"

require "support/project_path_macro"

describe Librarian::Posix do
  include Support::ProjectPathMacro

  let(:tmp_path) { project_path + "tmp/spec/functional/posix" }
  after { tmp_path.rmtree if tmp_path && tmp_path.exist? }

  describe ".run!" do

    it "returns the stdout" do
      res = described_class.run!(%w[echo hello there]).strip
      expect(res).to eq "hello there"
    end

    it "changes directory" do
      tmp_path.mkpath
      res = described_class.run!(%w[pwd], :chdir => tmp_path).strip
      expect(res).to eq tmp_path.to_s
    end

    it "reads the env" do
      res = described_class.run!(%w[env], :env => {"KOALA" => "BEAR"})
      line = res.lines.find{|l| l.start_with?("KOALA=")}.strip
      expect(line).to eq "KOALA=BEAR"
    end

  end

end
