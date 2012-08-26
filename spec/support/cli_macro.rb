require "thor"

require "librarian/helpers"

module CliMacro

  class FakeShell < Thor::Shell::Basic
    def stdout
      @stdout ||= StringIO.new
    end
    def stderr
      @stderr ||= StringIO.new
    end
    def stdin
      raise "unsupported"
    end
  end

  def self.included(base)
    base.instance_exec do
      let(:project_path) do
        project_path = Pathname.new(__FILE__).expand_path
        project_path = project_path.dirname until project_path.join("Rakefile").exist?
        project_path
      end
      let(:tmp) { project_path.join("tmp/spec/cli") }
      let(:pwd) { tmp + SecureRandom.hex(8) }
      let(:shell) { FakeShell.new }

      before { tmp.mkpath }
      before { pwd.mkpath }

      after  { tmp.rmtree }
    end
  end

  def cli!(*args)
    Dir.chdir(pwd) do
      described_class.start args, :shell => shell
    end
  end

  def write_file!(path, content)
    pwd.join(path).open("wb"){|f| f.write(content)}
  end

  def strip_heredoc(text)
    Librarian::Helpers.strip_heredoc(text)
  end

  def stdout
    shell.stdout.string
  end

end
