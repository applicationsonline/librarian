module Librarian
  module ManifestVersion
    ##
    # Version scheme which implements Semantic Versioning
    #
    # For more information, see the {Semantic Versioning 2.0.0 Specification}[http://semver.org/spec/v2.0.0.html]
    class SemanticVersion
      include Comparable
      ##
      # Encapsulates the comparison of the pre-release portion of a semver
      #
      class PreReleaseVersion
        include Comparable
        # Compares pre-release component ids using Semver 2.0.0 spec
        def self.compare_components(this_id,other_id)
          case # Strings have higher precedence than numbers
            when (this_id.is_a?(Integer) and other_id.is_a?(String))
              -1
            when (this_id.is_a?(String) and other_id.is_a?(Integer))
              1
            else
              this_id <=> other_id
          end
        end

        # Parses pre-release components `a.b.c` into an array ``[a,b,c]`
        # Converts numeric components into +Integer+
        def self.parse(prerelease)
          if prerelease.nil?
            []
          else
            prerelease.split('.').collect do |id|
              id = Integer(id) if /^[0-9]+$/ =~ id
              id
            end
          end
        end

        attr_reader :components

        def initialize(prerelease)
          @prerelease = prerelease
          @components = PreReleaseVersion.parse(prerelease)
        end

        def to_s
          @prerelease
        end

        def <=>(other)
          # null-fill zip array to prevent loss of components
          z = Array.new([components.length,other.components.length])

          # Compare each component against the other
          comp = z.zip(components,other.components).collect do |ids|
            case # All components being equal, the version with more of them takes precedence
              when ids[1].nil? # Self has less elements, other wins
                -1
              when ids[2].nil? # Other has less elements, self wins
                1
              else
                PreReleaseVersion.compare_components(ids[1],ids[2])
            end
          end
          # Chose the first non-zero comparison or return 0
          comp.delete_if {|c| c == 0}[0] || 0
        end
      end

      @@VERSION_PATTERN = /^([0-9]+\.[0-9]+(?:\.[0-9]+)?)(?:-([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?(?:\+([0-9A-Za-z-]+(?:\.[0-9A-Za-z-]+)*))?$/
      def self.parse_semver(version_string)
        parsed = @@VERSION_PATTERN.match(version_string.strip)
        if parsed
          {
              :full_version => parsed[0],
              :version => parsed[1],
              :prerelease => (PreReleaseVersion.new(parsed[2]) if parsed[2]),
              :build => parsed[3]
          }
        end
      end

      def initialize(semver)
        parsed = SemanticVersion.parse_semver(semver)
        raise ArgumentError, "Invalid Semantic Version string #{semver}" unless parsed
        @version = Gem::Version.new(parsed[:version])
        @prerelease = parsed[:prerelease]
        @full_version = parsed[:full_version]

      end

      def <=>(other)
        cmp = version <=> other.version

        # Should compare pre-release versions?
        if cmp == 0 and not (prerelease.nil? and other.prerelease.nil?)
          case # Versions without prerelease take precedence
            when (prerelease.nil? and not other.prerelease.nil?)
              1
            when (not prerelease.nil? and other.prerelease.nil?)
              -1
            else
              prerelease <=> other.prerelease
          end
        else
          cmp
        end
      end

      def to_s
        @full_version
      end

      attr_reader :prerelease
      attr_reader :version

    end
  end
end