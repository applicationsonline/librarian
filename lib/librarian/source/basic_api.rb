module Librarian
  module Source
    module BasicApi

      def self.included(base)
        base.extend ClassMethods
        class << base
          def lock_name(name)
            def_sclass_prop(:lock_name, name)
          end

          def spec_options(keys)
            def_sclass_prop(:spec_options, keys)
          end

        private

          def def_sclass_prop(name, arg)
            sclass = class << self ; self ; end
            sclass.module_exec do
              remove_method(name)
              define_method(name) { arg }
            end
          end
        end
      end

      module ClassMethods
        def from_lock_options(environment, options)
          new(environment, options[:remote], options.reject{|k, v| k == :remote})
        end

        def from_spec_args(environment, param, options)
          recognized_options = spec_options
          unrecognized_options = options.keys - recognized_options
          unrecognized_options.empty? or raise Error,
            "unrecognized options: #{unrecognized_options.join(", ")}"

          new(environment, param, options)
        end
      end

    end
  end
end
