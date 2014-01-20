require "librarian/error"

module Librarian
  class Environment
    class RuntimeCache

      def initialize
        self.data = {}
      end

      def include?(keyspace, key)
        data.include?(combined_key(keyspace, key))
      end

      def get(keyspace, key)
        data[combined_key(keyspace, key)]
      end

      def put(keyspace, key, value)
        data[combined_key(keyspace, key)] = value
      end

      def delete(keyspace, key)
        data.delete(combined_key(keyspace, key))
      end

      def memo(keyspace, key)
        put(keyspace, key, yield) unless include?(keyspace, key)
        get(keyspace, key)
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
