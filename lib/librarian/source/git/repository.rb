require 'open3'
require 'securerandom'
require 'shellwords'

require 'librarian/helpers'
require 'librarian/helpers/debug'

module Librarian
  module Source
    class Git
      class Repository

        class << self
          def clone!(root_module, path, repository_url, options = {})
            path = Pathname.new(path)
            path.mkpath
            git = new(root_module, path, options)
            git.clone!(repository_url)
            git
          end
        end

        include Helpers::Debug

        attr_reader :root_module, :path, :key

        def initialize(root_module, path, options = {})
          path = Pathname.new(path)
          @root_module = root_module
          @path = path
          @key = options[:key]
        end

        def git?
          path.join('.git').exist?
        end

        def clone!(repository_url)
          within do
            command = %W(clone #{repository_url} .)
            run!(command)
          end
        end

        def checkout!(reference)
          within do
            command = %W(checkout #{reference})
            run!(command)
          end
        end

        def hash_from(reference)
          within do
            command = %W(rev-parse #{reference})
            run!(command)
          end
        end

        def current_commit_hash
          within do
            command = %W(rev-parse HEAD)
            run!(command).strip!
          end
        end

      private

        def ssh_wrapper
          if key
            @ssh_wrapper ||= begin
              t = Tempfile.open(SecureRandom.hex(16))
              t.chmod(0500)
              t.binmode
              t.write Helpers.strip_heredoc(<<-GITSSH)
                #!/usr/bin/env bash
                /usr/bin/env ssh -o "StrictHostKeyChecking=no" -i #{key.shellescape} $1 $2
              GITSSH
              t.flush
              t.close
              t
            end
          end
        end

        def run!(command)
          text = "git #{command.shelljoin} --quiet"
          text = "/usr/bin/env GIT_SSH=#{ssh_wrapper.path.shellescape} #{text}" if key
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
