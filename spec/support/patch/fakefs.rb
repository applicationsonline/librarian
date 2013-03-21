require "fakefs/safe"

module FakeFS
  if RUBY_VERSION >= "1.9.3"

    class Pathname

      # FakeFS doesn't do this. Odd! So we must.
      def read(*args, &block)
        File.read(to_s, *args, &block)
      end

    end

  end
end
