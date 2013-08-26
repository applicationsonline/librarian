require "fakefs/safe"
require "fakefs/spec_helpers"
require "support/method_patch_macro"

if defined?(Rubinius)
  module Rubinius
    class CodeLoader
      class << self
        alias_method :require_fakefs_original, :require
        def require(s)
          ::FakeFS.without { require_fakefs_original(s) }
        end
      end
    end
  end
end

module Support
  module FakeFS

    def self.included(base)
      base.module_exec do
        include ::FakeFS::SpecHelpers
      end

      # Since ruby-1.9.3-p286, Kernel#Pathname was changed in a way that broke
      # FakeFS's assumptions. It used to lookup the Pathname constant (which is
      # where FakeFS hooks) and send it #new, but now it keeps a reference to
      # the Pathname constant (breaking the FakeFS hook).
      base.module_exec do
        include MethodPatchMacro
        with_module_method(Kernel, :Pathname){|s| Pathname.new(s)}
      end
    end

  end
end
