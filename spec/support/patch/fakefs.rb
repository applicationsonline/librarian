require "fakefs/safe"

module FakeFS
  class Pathname

    # FakeFS doesn't do this. Odd! So we must.
    def read(*args, &block)
      File.read(to_s, *args, &block)
    end

  end
end
