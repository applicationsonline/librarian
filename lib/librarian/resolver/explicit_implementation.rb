require 'librarian/dependency'

module Librarian
  class Resolver
    class ExplicitImplementation

      class MultiSource
        attr_accessor :sources
        def initialize(sources)
          self.sources = sources
        end
        def manifests(name)
          sources.reverse.map{|source| source.manifests(name)}.flatten(1)
        end
      end

      class SResolvedSet
        include Enumerable
        def initialize(data = {})
          self.rep = data
        end
        def add(o)
          data.include?(o.name) and raise Error, "cannot add included #{o.name.inspect}"
          new_data = rep.dup
          new_data[o.name] = o
          self.class.new(new_data)
        end
        def each
          Enumerator.new{|y| data.each{|_, o| y << o}}
        end
        private
        attr_accessor :rep
      end

      class SUnresolvedQueue
        def self.from_array(array)
          array.inject(new){|accum, el| accum.enqueue(el)}
        end
        def initialize(data = [])
          self.rep = data
        end
        def empty?
          rep.size == 0
        end
        def peek
          empty? and raise Error, "cannot peek when empty"
          rep.first
        end
        def enqueue(o)
          new_data = rep.dup
          new_data << o
          self.class.new(new_data)
        end
        def dequeue
          empty? and raise Error, "cannot dequeue when empty"
          new_data = rep.dup
          new_data.shift
          self.class.new(new_data)
        end
        def possible?(manifests)
          rep.all? do |d|
            m = manifests[d.name]
            !m || m.satisfied_by?(d)
          end
        end
        def impossible?(manifests)
          !possible?(manifests)
        end
        private
        attr_accessor :rep
      end

      class SManifestSet
        def self.from_array(array)
          array.inject(new){|accum, el| accum.add(el)}
        end
        include Enumerable
        def initialize(data = {})
          self.rep = data
        end
        def [](key)
          rep[key]
        end
        def add(manifest)
          include?(manifest.name) and raise Error, "cannot add included #{manifest.name.inspect}"
          new_data = rep.dup
          new_data[manifest.name] = manifest
          self.class.new(new_data)
        end
        def each
          Enumerator.new{|y| data.each{|_, m| y << m}}
        end
        private
        attr_accessor :rep
      end

      class SBacktrackStack
        def initialize(data = [])
          self.rep = data
        end
        def empty?
          rep.size == 0
        end
        def top
          empty? and raise Error, "cannot top when empty"
          rep.last
        end
        def pop
          empty? and raise Error, "cannot pop when empty"
          new_data = rep.dup
          new_data.pop
          self.class.new(new_data)
        end
        def push(state)
          new_data = rep.dup
          new_data.push(state)
          self.class.new(new_data)
        end
        private
        attr_accessor :rep
      end

      class SContext
        attr_accessor :resolver
        private :resolver=
        def initialize(resolver, spec)
          self.resolver = resolver
          self.source = MultiSource.new(spec.sources)
          self.dependency_source_map = Hash[spec.dependencies.map{|d| [d.name, d.source]}]
        end
        def source_for(name)
          dependency_source_map[name] || source
        end
        private
        attr_accessor :source, :dependency_source_map
      end

      class State
        attr_accessor :context, :backtrack, :resolved, :unresolved, :manifests

        def initialize(context, backtrack, resolved, unresolved, manifests)
          assert_consistency! resolved, manifests

          self.context    = context
          self.backtrack  = backtrack
          self.resolved   = resolved
          self.unresolved = unresolved
          self.manifests  = manifests
        end

        def resolved?
          return false unless unresolved.empty?
          return false unless resolved.all?{|d| manifests[d.name]}
          true
        end

        def impossible?
          unresolved.impossible?(manifests)
        end

        def step?
          !resolved? && !impossible?
        end

        def step
          # ???
        end

        def resolution
          impossible? ? nil : manifests.to_a
        end

        private

        def context=(context)
          assert_kind! "context", context, SContext
          @context = context
        end

        def backtrack=(backtrack)
          assert_kind! "backtrack", backtrack, SBacktrackStack
          @backtrack = backtrack
        end

        def resolved=(resolved)
          assert_kind! "resolved", resolved, SResolvedSet
          @resolved = resolved
        end

        def unresolved=(unresolved)
          assert_kind! "unresolved", unresolved, SUnresolvedQueue
          @unresolved = unresolved
        end

        def manifests=(manifests)
          assert_kind! "manifests", manifests, SManifestSet
          @manifests = manifests
        end

        def assert_kind!(name, var, type)
          type === var or raise TypeError, "#{name} must be #{type}"
        end

        def assert_consistency!(resolved, manifests)
          resolved.each do |d|
            next unless m = manifests[d.name]
            d.satisfied_by?(m) or raise Error, "inconsistent state"
          end
          manifests.each do |m|
            m.dependencies.each do |d|
              next unless mm = manifests[d.name]
              d.satisfied_by?(mm) or raise Error, "inconsistent state"
            end
          end
        end
      end

      attr_accessor :resolver, :context
      private :resolver=, :context=

      def initialize(resolver, spec)
        self.resolver = resolver
        self.context  = SContext.new(resolver, spec)
      end

      def resolve(dependencies, manifests = [])
        unresolved  = SUnresolvedQueue.from_array(dependencies)
        resolved    = SResolvedSet.new
        manifests   = SManifestSet.from_array(manifests)
        backtrack   = SBacktrackStack.new

        state = State.new(context, backtrack, resolved, unresolved, manifests)
        state = state.step while state.step?
        state.resolution
      end

    end
  end
end
