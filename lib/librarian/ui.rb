require 'rubygems/user_interaction'

module Librarian
  class UI
    def warn
    end

    def debug
    end

    def error
    end

    def info
    end

    def confirm
    end

    class Shell < UI
      attr_writer :shell

      def initialize(shell)
        @shell = shell
        @quiet = false
        @debug = ENV['DEBUG']
      end

      def debug
        @shell.say(yield) if @debug && !@quiet
      end

      def info
        @shell.say(yield) if !@quiet
      end

      def confirm
        @shell.say(yield, :green) if !@quiet
      end

      def warn
        @shell.say(yield, :yellow)
      end

      def error
        @shell.say(yield, :red)
      end

      def be_quiet!
        @quiet = true
      end

      def debug!
        @debug = true
      end
    end
  end
end