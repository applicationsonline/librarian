module Librarian
  module Source
    module BasicApi

      def self.included(base)
        base.extend ClassMethods
        class << base
          def lock_name(name)
            sclass = (class << self ; self ; end)
            sclass.module_exec do
              remove_method(:lock_name)
              define_method(:lock_name) { name }
            end
          end
        end
      end

      module ClassMethods
        def from_lock_options(environment, options)
          new(environment, options[:remote], options.reject{|k, v| k == :remote})
        end
      end

    end
  end
end
