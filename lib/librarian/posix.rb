require "open3"

require "librarian/error"

module Librarian
  module Posix

    class << self

      # Cross-platform way of finding an executable in the $PATH.
      #
      #   which('ruby') #=> /usr/bin/ruby
      #
      # From:
      #   https://github.com/defunkt/hub/commit/353031307e704d860826fc756ff0070be5e1b430#L2R173
      def which(cmd)
        exts = ENV["PATHEXT"] ? ENV["PATHEXT"].split(';') : ['']
        ENV["PATH"].split(File::PATH_SEPARATOR).each do |path|
          path = File.expand_path(path)
          exts.each do |ext|
            exe = File.join(path, cmd + ext)
            return exe if File.file?(exe) && File.executable?(exe)
          end
        end
        nil
      end

      def which!(cmd)
        which(cmd) or raise Error, "cannot find #{cmd}"
      end

    end

    class CommandFailure < Error
      class << self
        def raise!(command, status, message)
          ex = new(message)
          ex.command = command
          ex.status = status
          ex.set_backtrace caller
          raise ex
        end
      end

      attr_accessor :command, :status
    end

    class << self

      if defined?(JRuby) # built with jruby-1.7.9 in mind

        def rescuing(*klasses)
          begin
            yield
          rescue *klasses
          end
        end

        def run!(command, options = { })
          out, err = nil, nil
          chdir = options[:chdir].to_s if options[:chdir]
          env = options[:env] || { }
          old_env = Hash[env.keys.map{|k| [k, ENV[k]]}]
          out, err, wait = nil, nil, nil
          begin
            ENV.update env
            Dir.chdir(chdir || Dir.pwd) do
              IO.popen3(*command) do |i, o, e, w|
                rescuing(Errno::EBADF){ i.close } # jruby/1.9 can raise EBADF
                out, err, wait = o.read, e.read, w
              end
            end
          ensure
            ENV.update old_env
          end
          s = wait ? wait.value : $? # wait is 1.9+-only
          s.success? or CommandFailure.raise! command, s, err
          out
        end

      else

        if RUBY_VERSION < "1.9"

          def run!(command, options = { })
            i, o, e = IO.pipe, IO.pipe, IO.pipe
            pid = fork do
              $stdin.reopen i[0]
              $stdout.reopen o[1]
              $stderr.reopen e[1]
              [i[1], i[0], o[0], e[0]].each &:close
              ENV.update options[:env] || { }
              Dir.chdir options[:chdir].to_s if options[:chdir]
              exec *command
            end
            [i[0], i[1], o[1], e[1]].each &:close
            Process.waitpid pid
            $?.success? or CommandFailure.raise! command, $?, e[0].read
            o[0].read
          ensure
            [i, o, e].flatten(1).each{|io| io.close unless io.closed?}
          end

        else

          def run!(command, options = { })
            i, o, e = IO.pipe, IO.pipe, IO.pipe
            opts = {:in => i[0], :out => o[1], :err => e[1]}
            opts[:chdir] = options[:chdir].to_s if options[:chdir]
            command = command.dup
            command.unshift options[:env] || { }
            command.push opts
            pid = Process.spawn(*command)
            [i[0], i[1], o[1], e[1]].each &:close
            Process.waitpid pid
            $?.success? or CommandFailure.raise! command, $?, e[0].read
            o[0].read
          ensure
            [i, o, e].flatten(1).each{|io| io.close unless io.closed?}
          end

        end

      end

    end

  end
end
