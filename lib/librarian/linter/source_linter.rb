module Librarian
  module Linter
    class SourceLinter

      class << self
        def lint!(klass)
          new(klass).lint!
        end
      end

      attr_accessor :klass
      private :klass=

      def initialize(klass)
        self.klass = klass
      end

      def lint!
        lint_class_responds_to! *[
          :lock_name,
          :from_spec_args,
          :from_lock_options,
        ]

        lint_instance_responds_to! *[
          :to_spec_args,
          :to_lock_options,
          :manifests,
          :fetch_version,
          :fetch_dependencies,
          :pinned?,
          :unpin!,
          :install!,
        ]
      end

    private

      def lint_class_responds_to!(*names)
        missing = names.reject{|name| klass.respond_to?(name)}
        return if missing.empty?

        raise "class must respond to #{missing.join(', ')}"
      end

      def lint_instance_responds_to!(*names)
        missing = names - klass.public_instance_methods.map(&:to_sym)
        return if missing.empty?

        raise "instance must respond to #{missing.join(', ')}"
      end

    end
  end
end
