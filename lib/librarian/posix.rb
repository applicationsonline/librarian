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

  end
end
