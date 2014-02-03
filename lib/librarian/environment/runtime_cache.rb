require "librarian/error"

module Librarian
  class Environment
    class RuntimeCache

      class KeyspaceCache

        class << self
          private

          def delegate_to_backing_cache(*methods)
            methods.each do |method|
              define_method "#{method}" do |*args, &block|
                # TODO: When we drop ruby-1.8.7 support, use #public_send.
                runtime_cache.send(method, keyspace, *args, &block)
              end
            end
          end
        end

        attr_reader :runtime_cache, :keyspace

        def initialize(runtime_cache, keyspace)
          self.runtime_cache = runtime_cache
          self.keyspace = keyspace
        end

        delegate_to_backing_cache *[
          :include?,
          :get,
          :put,
          :delete,
          :memo,
          :once,
          :[],
          :[]=,
        ]

        private

        attr_writer :runtime_cache, :keyspace

      end

      def initialize
        self.data = {}
      end

      def include?(keyspace, key)
        data.include?(combined_key(keyspace, key))
      end

      def get(keyspace, key)
        data[combined_key(keyspace, key)]
      end

      def put(keyspace, key, value = nil)
        data[combined_key(keyspace, key)] = block_given? ? yield : value
      end

      def delete(keyspace, key)
        data.delete(combined_key(keyspace, key))
      end

      def memo(keyspace, key)
        put(keyspace, key, yield) unless include?(keyspace, key)
        get(keyspace, key)
      end

      def once(keyspace, key)
        memo(keyspace, key) { yield ; nil }
      end

      def [](keyspace, key)
        get(keyspace, key)
      end

      def []=(keyspace, key, value)
        put(keyspace, key, value)
      end

      def keyspace(keyspace)
        KeyspaceCache.new(self, keyspace)
      end

      private

      attr_accessor :data

      def combined_key(keyspace, key)
        keyspace.kind_of?(String) or raise Error, "keyspace must be a string"
        keyspace.size > 0 or raise Error, "keyspace must not be empty"
        keyspace.size < 2**16 or raise Error, "keyspace must not be too large"
        key.kind_of?(String) or raise Error, "key must be a string"
        [keyspace.size.to_s(16).rjust(4, "0"), keyspace, key].join
      end

    end
  end
end
