require "librarian/posix"

module Librarian
  module Source
    class Git
      class Repository

        class << self
          def clone!(environment, path, repository_url)
            path = Pathname.new(path)
            path.mkpath
            git = new(environment, path)
            git.clone!(repository_url)
            git
          end

          def bin
            @bin ||= Posix.which!("git")
          end

          def git_version
            command = %W[#{bin} version --silent]
            Posix.run!(command).strip =~ /([.\d]+)$/ && $1
          end
        end

        attr_accessor :environment, :path
        private :environment=, :path=

        def initialize(environment, path)
          self.environment = environment
          self.path = Pathname.new(path)
        end

        def git?
          path.join('.git').exist?
        end

        def default_remote
          "origin"
        end

        def clone!(repository_url)
          command = %W(clone #{repository_url} . --quiet)
          run!(command, :chdir => true)
        end

        def checkout!(reference, options ={ })
          command = %W(checkout #{reference} --quiet)
          command << "--force" if options[:force]
          run!(command, :chdir => true)
        end

        def fetch!(remote, options = { })
          command = %W(fetch #{remote} --quiet)
          command << "--tags" if options[:tags]
          run!(command, :chdir => true)
        end

        def reset_hard!
          command = %W(reset --hard --quiet)
          run!(command, :chdir => true)
        end

        def clean!
          command = %w(clean -x -d --force --force)
          run!(command, :chdir => true)
        end

        def checked_out?(sha)
          current_commit_hash == sha
        end

        def remote_names
          command = %W(remote)
          run!(command, :chdir => true).strip.lines.map(&:strip)
        end

        def remote_branch_names
          remotes = remote_names.sort_by(&:length).reverse

          command = %W(branch -r --no-color)
          names = run!(command, :chdir => true).strip.lines.map(&:strip).to_a
          names.each{|n| n.gsub!(/\s*->.*$/, "")}
          names.reject!{|n| n =~ /\/HEAD$/}
          Hash[remotes.map do |r|
            matching_names = names.select{|n| n.start_with?("#{r}/")}
            matching_names.each{|n| names.delete(n)}
            matching_names.each{|n| n.slice!(0, r.size + 1)}
            [r, matching_names]
          end]
        end

        def hash_from(remote, reference)
          branch_names = remote_branch_names[remote]
          if branch_names.include?(reference)
            reference = "#{remote}/#{reference}"
          end

          command = %W(rev-list #{reference} -1)
          run!(command, :chdir => true).strip
        end

        def current_commit_hash
          command = %W(rev-parse HEAD --quiet)
          run!(command, :chdir => true).strip!
        end

      private

        def bin
          self.class.bin
        end

        def run!(args, options = { })
          chdir = options.delete(:chdir)
          chdir = path.to_s if chdir == true

          silent = options.delete(:silent)
          pwd = chdir || Dir.pwd
          git_dir = File.join(path, ".git") if path
          env = {"GIT_DIR" => git_dir}

          command = [bin]
          command.concat(args)

          logging_command(command, :silent => silent, :pwd => pwd) do
            Posix.run!(command, :chdir => chdir, :env => env)
          end
        end

        def logging_command(command, options)
          silent = options.delete(:silent)

          pwd = Dir.pwd

          out = yield

          unless silent
            if out.size > 0
              out.lines.each do |line|
                debug { "    --> #{line}" }
              end
            else
              debug { "    --- No output" }
            end
          end

          out
        end

        def debug(*args, &block)
          environment.logger.debug(*args, &block)
        end

        def relative_path_to(path)
          environment.logger.relative_path_to(path)
        end

      end
    end
  end
end
