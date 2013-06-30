require "librarian/error"
require "librarian/spec_change_set"

module Librarian
  module Action
    module PersistResolutionMixin

    private

      def persist_resolution(resolution)
        resolution && resolution.correct? or raise Error,
          "Could not resolve the dependencies."

        lockfile_text = lockfile.save(resolution)
        debug { "Bouncing #{lockfile_name}" }
        bounced_lockfile_text = lockfile.save(lockfile.load(lockfile_text))
        unless bounced_lockfile_text == lockfile_text
          debug { "lockfile_text: \n#{lockfile_text}" }
          debug { "bounced_lockfile_text: \n#{bounced_lockfile_text}" }
          raise Error, "Cannot bounce #{lockfile_name}!"
        end
        lockfile_path.open('wb') { |f| f.write(lockfile_text) }
      end

      def specfile_name
        environment.specfile_name
      end

      def lockfile_name
        environment.lockfile_name
      end

      def specfile_path
        environment.specfile_path
      end

      def lockfile_path
        environment.lockfile_path
      end

      def specfile
        environment.specfile
      end

      def lockfile
        environment.lockfile
      end

    end
  end
end
