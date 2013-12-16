require "fileutils"
require "pathname"
require "tmpdir"
require "yaml"

require "support/fakefs"

require "librarian/config/database"

describe Librarian::Config::Database do
  include ::Support::FakeFS

  def write_yaml!(path, *yamlables)
    path = Pathname(path)
    path.dirname.mkpath unless path.dirname.directory?
    File.open(path, "wb"){|f| yamlables.each{|y| YAML.dump(y, f)}}
  end

  let(:adapter_name) { "gem" }

  let(:env) { { } }
  let(:pwd) { Pathname(Dir.tmpdir) }
  let(:home) { Pathname("~").expand_path }
  let(:project_path) { nil }
  let(:specfile_name) { nil }
  let(:global) { home.join(".librarian/gem/config") }
  let(:local) { pwd.join(".librarian/gem/config") }
  let(:specfile) { pwd.join("Gemfile") }

  before do
    FileUtils.mkpath(pwd)
    FileUtils.touch(specfile)
  end

  let(:database) do
    described_class.new(adapter_name,
      :env => env,
      :pwd => pwd.to_s,
      :home => home.to_s,
      :project_path => project_path,
      :specfile_name => specfile_name
    )
  end

  context "when a key is given globally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      write_yaml! global, raw_key => value
    end

    it "should have the key globally" do
      expect(database.global[key]).to eq value
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should not have the key locally" do
      expect(database.local[key]).to be_nil
    end

    it "should have the key generally" do
      expect(database[key]).to eq value
    end
  end

  context "when a key is set globally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      database.global[key] = value
    end

    it "should have the key globally" do
      expect(database.global[key]).to eq value
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should not have the key locally" do
      expect(database.local[key]).to be_nil
    end

    it "should have the key generally" do
      expect(database[key]).to eq value
    end

    it "should persist the key" do
      data = YAML.load_file(global)

      expect(data).to eq ({raw_key => value})
    end
  end

  context "when the key is set and unset globally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      database.global[key] = value
      database.global[key] = nil
    end

    it "should not have the key globally" do
      expect(database.global[key]).to be_nil
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should not have the key locally" do
      expect(database.local[key]).to be_nil
    end

    it "should not have the key generally" do
      expect(database[key]).to be_nil
    end

    it "should unpersist the key" do
      expect(File).to_not exist global
    end
  end

  context "when a key is given in the env" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    #override
    let(:env) { {raw_key => value} }

    it "should not have the key globally" do
      expect(database.global[key]).to be_nil
    end

    it "should have the key in the env" do
      expect(database.env[key]).to eq value
    end

    it "should not have the key locally" do
      expect(database.local[key]).to be_nil
    end

    it "should have the key generally" do
      expect(database[key]).to eq value
    end
  end

  context "when a key is given locally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      write_yaml! local, raw_key => value
    end

    it "should not have the key globally" do
      expect(database.global[key]).to be_nil
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should have the key locally" do
      expect(database.local[key]).to eq value
    end

    it "should have the key generally" do
      expect(database[key]).to eq value
    end
  end

  context "when a key is set locally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      database.local[key] = value
    end

    it "should not have the key globally" do
      expect(database.global[key]).to be_nil
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should have the key locally" do
      expect(database.local[key]).to eq value
    end

    it "should have the key generally" do
      expect(database[key]).to eq value
    end

    it "should persist the key" do
      data = YAML.load_file(local)

      expect(data).to eq ({raw_key => value})
    end
  end

  context "when the key is set and unset locally" do
    let(:key) { "jam" }
    let(:value) { "jelly" }
    let(:raw_key) { "LIBRARIAN_GEM_JAM" }

    before do
      database.local[key] = value
      database.local[key] = nil
    end

    it "should not have the key globally" do
      expect(database.global[key]).to be_nil
    end

    it "should not have the key in the env" do
      expect(database.env[key]).to be_nil
    end

    it "should not have the key locally" do
      expect(database.local[key]).to be_nil
    end

    it "should not have the key generally" do
      expect(database[key]).to be_nil
    end

    it "should unpersist the key" do
      expect(File).to_not exist local
    end
  end

  context "setting malformatted keys" do
    it "should ban caps" do
      expect { database.global["JAM"] = "jelly" }.
        to raise_error Librarian::Error, %[key not permitted: "JAM"]
    end

    it "should ban double dots" do
      expect { database.global["jam..jam"] = "jelly" }.
        to raise_error Librarian::Error, %[key not permitted: "jam..jam"]
    end
  end

  context "setting banned keys" do
    it  "should ban the specfile key" do
      expect { database.global["gemfile"] = "jelly" }.
        to raise_error Librarian::Error, %[key not permitted: "gemfile"]
    end

    it  "should ban the global-config key" do
      expect { database.global["config"] = "jelly" }.
        to raise_error Librarian::Error, %[key not permitted: "config"]
    end
  end

  context "project_path" do
    context "by default" do
      it "should give the default project path" do
        expect(database.project_path).to eq Pathname("/tmp")
      end
    end

    context "when the specfile is set in the env" do
      let(:env) { {"LIBRARIAN_GEM_GEMFILE" => "/non/sense/path/to/Sillyfile"} }

      it "should give the project path from the env-set specfile" do
        expect(database.project_path).to eq Pathname("/non/sense/path/to")
      end
    end
  end

  context "specfile_path" do
    context "by default" do
      it "should give the default specfile path" do
        expect(database.specfile_path).to eq specfile
      end
    end

    context "when set in the env" do
      let(:env) { {"LIBRARIAN_GEM_GEMFILE" => "/non/sense/path/to/Sillyfile"} }

      it "should give the given specfile path" do
        expect(database.specfile_path).to eq Pathname("/non/sense/path/to/Sillyfile")
      end
    end

    context "when the project_path is assigned" do
      let(:project_path) { "/non/sense/path/to" }

      it "should give the assigned specfile path" do
        expect(database.specfile_path).to eq Pathname("/non/sense/path/to/Gemfile")
      end
    end

    context "when the specfile_name is assigned" do
      let(:specfile_name) { "Sillyfile" }

      it "should give the assigned specfile path" do
        expect(database.specfile_path).to eq Pathname("/tmp/Sillyfile")
      end
    end
  end

end
