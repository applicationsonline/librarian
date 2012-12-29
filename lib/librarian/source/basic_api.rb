module Librarian
  module Source
    module BasicApi

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def from_lock_options(environment, options)
          new(environment, options[:remote], options.reject{|k, v| k == :remote})
        end
      end

    end
  end
end
