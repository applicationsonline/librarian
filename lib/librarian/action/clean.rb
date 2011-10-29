require "librarian/action"

module Librarian
  class Action
    class Clean < Action

      def run
        clean_cache_path
        clean_install_path
        clean_lockfile_path
      end

    private

      def clean_cache_path
        if cache_path.exist?
          debug { "Deleting #{project_relative_path_to(cache_path)}" }
          cache_path.rmtree
        end
      end

      def clean_install_path
        if install_path.exist?
          install_path.children.each do |c|
            debug { "Deleting #{project_relative_path_to(c)}" }
            c.rmtree unless c.file?
          end
        end
      end

      def clean_lockfile_path
        if lockfile_path.exist?
          debug { "Deleting #{project_relative_path_to(lockfile_path)}" }
          lockfile_path.rmtree
        end
      end

      def cache_path
        environment.cache_path
      end

      def install_path
        environment.install_path
      end

      def lockfile_path
        environment.lockfile_path
      end

      def project_relative_path_to(path)
        environment.project_relative_path_to(path)
      end

    end
  end
end
