module Librarian
  module ManifestVersion
    class GemVersion
      include Comparable

      def initialize(*args)
        args = initialize_normalize_args(args)

        self.backing = Gem::Version.new(*args)
      end

      def to_gem_version
        backing
      end

      def <=>(other)
        to_gem_version <=> other.to_gem_version
      end

      def to_s
        to_gem_version.to_s
      end

      def inspect
        "#<#{self.class} #{to_s}>"
      end

      private

      def initialize_normalize_args(args)
        args.map do |arg|
          arg = [arg] if self.class === arg
          arg
        end
      end

      attr_accessor :backing
    end
  end
end