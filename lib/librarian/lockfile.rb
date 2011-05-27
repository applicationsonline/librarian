require 'librarian/helpers/debug'

require 'librarian/lockfile/compiler'
require 'librarian/lockfile/parser'

module Librarian
  class Lockfile

    include Helpers::Debug

    attr_reader :root_module, :path

    def initialize(root_module, path)
      @root_module = root_module
      @path = path
    end

    def save(resolution)
      Compiler.new(root_module).compile(resolution)
    end

    def load(string)
      Parser.new(root_module).parse(string)
    end

    def read
      load(path.read)
    end

  end
end
