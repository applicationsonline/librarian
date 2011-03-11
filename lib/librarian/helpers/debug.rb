require 'librarian/support/abstract_method'

module Librarian
  module Helpers
    module Debug

      include Support::AbstractMethod

      LIBRARIAN_PATH = Pathname.new('../../../../').expand_path(__FILE__)

      abstract_method :root_module

    private

      def relative_path_to(path)
        root_module.project_relative_path_to(path)
      end

      def debug
        if root_module.ui
          loc = caller.find{|l| !(l =~ /in `debug'$/)}
          if loc =~ /^(.+):(\d+):in `(.+)'$/
            loc = "#{Pathname.new($1).relative_path_from(LIBRARIAN_PATH)}:#{$2}:in `#{$3}'"
          end
          root_module.ui.debug { "[Librarian] #{yield} [#{loc}]" }
        end
      end

    end
  end
end
