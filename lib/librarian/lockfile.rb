require 'librarian/helpers/debug'

require 'librarian/lockfile/compiler'
require 'librarian/lockfile/parser'

module Librarian
  class Lockfile

    include Helpers::Debug

    attr_reader :environment, :path

    def initialize(environment, path)
      @environment = environment
      @path = path
    end

    def save(resolution)
      Compiler.new(environment).compile(resolution)
    end

    def load(string)
      Parser.new(environment).parse(string)
    end

    def read
      load(path.read)
    end

  end
end
