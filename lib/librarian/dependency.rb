require 'rubygems'

module Librarian
  class Dependency

    class Requirement
      def initialize(*args)
        args = initialize_normalize_args(args)

        self.backing = Gem::Requirement.create(*args)
      end

      def to_gem_requirement
        backing
      end

      def satisfied_by?(version)
        to_gem_requirement.satisfied_by?(version.to_gem_version)
      end

      def ==(other)
        to_gem_requirement == other.to_gem_requirement
      end

      def to_s
        to_gem_requirement.to_s
      end

      def inspect
        "#<#{self.class} #{to_s}>"
      end

      COMPATS_TABLE = {
        %w(=  = ) => lambda{|s, o| s == o},
        %w(=  !=) => lambda{|s, o| s != o},
        %w(=  > ) => lambda{|s, o| s >  o},
        %w(=  < ) => lambda{|s, o| s <  o},
        %w(=  >=) => lambda{|s, o| s >= o},
        %w(=  <=) => lambda{|s, o| s <= o},
        %w(=  ~>) => lambda{|s, o| s >= o && s.release < o.bump},
        %w(!= !=) => true,
        %w(!= > ) => true,
        %w(!= < ) => true,
        %w(!= >=) => true,
        %w(!= <=) => true,
        %w(!= ~>) => true,
        %w(>  > ) => true,
        %w(>  < ) => lambda{|s, o| s < o},
        %w(>  >=) => true,
        %w(>  <=) => lambda{|s, o| s < o},
        %w(>  ~>) => lambda{|s, o| s < o.bump},
        %w(<  < ) => true,
        %w(<  >=) => lambda{|s, o| s > o},
        %w(<  <=) => true,
        %w(<  ~>) => lambda{|s, o| s > o},
        %w(>= >=) => true,
        %w(>= <=) => lambda{|s, o| s <= o},
        %w(>= ~>) => lambda{|s, o| s < o.bump},
        %w(<= <=) => true,
        %w(<= ~>) => lambda{|s, o| s >= o},
        %w(~> ~>) => lambda{|s, o| s < o.bump && s.bump > o},
      }

      def consistent_with?(other)
        sgreq, ogreq = to_gem_requirement, other.to_gem_requirement
        sreqs, oreqs = sgreq.requirements, ogreq.requirements
        sreqs.all? do |sreq|
          oreqs.all? do |oreq|
            compatible?(sreq, oreq)
          end
        end
      end

      def inconsistent_with?(other)
        !consistent_with?(other)
      end

      protected

      attr_accessor :backing

      private

      def initialize_normalize_args(args)
        args.map do |arg|
          arg = arg.backing if self.class === arg
          arg
        end
      end

      def compatible?(a, b)
        a, b = b, a unless COMPATS_TABLE.include?([a.first, b.first])
        r = COMPATS_TABLE[[a.first, b.first]]
        r = r.call(a.last, b.last) if r.respond_to?(:call)
        r
      end
    end

    attr_accessor :name, :requirement, :source
    private :name=, :requirement=, :source=

    def initialize(name, requirement, source)
      assert_name_valid! name

      self.name = name
      self.requirement = Requirement.new(requirement)
      self.source = source

      @manifests = nil
    end

    def manifests
      @manifests ||= cache_manifests!
    end

    def cache_manifests!
      source.manifests(name)
    end

    def satisfied_by?(manifest)
      manifest.satisfies?(self)
    end

    def to_s
      "#{name} (#{requirement}) <#{source}>"
    end

    def ==(other)
      !other.nil? &&
      self.class        == other.class        &&
      self.name         == other.name         &&
      self.requirement  == other.requirement  &&
      self.source       == other.source
    end

    def consistent_with?(other)
      name != other.name || requirement.consistent_with?(other.requirement)
    end

    def inconsistent_with?(other)
      !consistent_with?(other)
    end

  private

    def assert_name_valid!(name)
      name =~ /\A\S(?:.*\S)?\z/ and return

      raise ArgumentError, "name (#{name.inspect}) must be sensible"
    end

  end
end
