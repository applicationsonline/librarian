require 'open3'

require 'librarian/helpers/debug'

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
        end

        include Helpers::Debug

        attr_accessor :environment
        private :environment=
        attr_reader :path

        def initialize(environment, path)
          self.environment = environment
          path = Pathname.new(path)
          @path = path
        end

        def git?
          path.join('.git').exist?
        end

        def default_remote
          "origin"
        end

        def clone!(repository_url)
          within do
            command = "clone #{repository_url} ."
            run!(command)
          end
        end

        def checkout!(reference, options ={ })
          within do
            command = "checkout #{reference}"
            command <<  " --force" if options[:force]
            run!(command)
          end
        end

        def fetch!(remote, options = { })
          within do
            command = "fetch #{remote}"
            command << " --tags" if options[:tags]
            run!(command)
          end
        end

        def reset_hard!
          within do
            command = "reset --hard"
            run!(command)
          end
        end

        def remote_names
          within do
            command = "remote"
            run!(command, false).strip.lines.map(&:strip)
          end
        end

        def remote_branch_names
          remotes = remote_names.sort_by(&:length).reverse

          within do
            command = "branch -r"
            names = run!(command, false).strip.lines.map(&:strip).to_a
            names.each{|n| n.gsub!(/\s*->.*$/, "")}
            names.reject!{|n| n =~ /\/HEAD$/}
            Hash[remotes.map do |r|
              matching_names = names.select{|n| n.start_with?("#{r}/")}
              matching_names.each{|n| names.delete(n)}
              matching_names.each{|n| n.slice!(0, r.size + 1)}
              [r, matching_names]
            end]
          end
        end

        def hash_from(remote, reference)
          branch_names = remote_branch_names[remote]
          if branch_names.include?(reference)
            reference = "#{remote}/#{reference}"
          end

          within do
            command = "rev-parse #{reference}"
            run!(command).strip
          end
        end

        def current_commit_hash
          within do
            command = "rev-parse HEAD"
            run!(command).strip!
          end
        end
      private

        def run!(text, quiet = true)
          text = "git #{text}"
          text << " --quiet" if quiet
          debug { "Running `#{text}` in #{relative_path_to(Dir.pwd)}" }
          out = Open3.popen3(text) do |i, o, e, t|
            raise StandardError, e.read unless (t ? t.value : $?).success?
            o.read
          end
          debug { "    ->  #{out}" } if out.size > 0
          out
        end

        def within
          Dir.chdir(path) { yield }
        end

      end
    end
  end
end
