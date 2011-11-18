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

        def clone!(repository_url)
          within do
            command = "clone #{repository_url} ."
            run!(command)
          end
        end

        def checkout!(reference)
          within do
            command = "checkout #{reference}"
            run!(command)
          end
        end

        def fetch!(options = { })
          within do
            command = "fetch"
            command << " --tags" if options[:tags]
            run!(command)
          end
        end

        def hash_from(reference)
          within do
            command = "rev-parse #{reference}"
            run!(command)
          end
        end

        def current_commit_hash
          within do
            command = "rev-parse HEAD"
            run!(command).strip!
          end
        end

      private

        def run!(text)
          text = "git #{text} --quiet"
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
