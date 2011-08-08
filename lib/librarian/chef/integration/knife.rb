require 'securerandom'

require 'librarian'
require 'librarian/chef'

module Librarian
  module Chef

    module KnifeIntegration
      def install_path
        @install_path ||= begin
          has_home = ENV["HOME"] && File.directory?(ENV["HOME"])
          tmp_dir = Pathname.new(has_home ? "~/.librarian/tmp" : "/tmp/librarian").expand_path
          enclosing = tmp_dir.join("chef/integration/knife/install")
          enclosing.mkpath unless enclosing.exist?
          dir = enclosing.join(SecureRandom.hex(16))
          dir.mkpath
          at_exit { dir.rmtree }
          dir
        end
      end
    end

    extend KnifeIntegration

    def install_consistent_resolution!
      raise Error, "#{specfile_name} missing!" unless specfile_path.exist?
      raise Error, "#{lockfile_name} missing!" unless lockfile_path.exist?

      previous_resolution = lockfile.load(lockfile_path.read)
      spec = specfile.read(previous_resolution.sources)
      spec_changes = spec_change_set(spec, previous_resolution)
      raise Error, "#{specfile_name} and #{lockfile_name} are out of sync!" unless spec_changes.same?

      previous_resolution.manifests.each do |manifest|
        manifest.install!
      end
    rescue Error => e
      hl = HighLine.new
      message = hl.color(e.message, HighLine::RED)
      hl.say(message)
      Process.exit!(1)
    end

    install_consistent_resolution!

  end
end
