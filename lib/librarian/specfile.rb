module Librarian
  class Specfile

    attr_reader :root_module, :path, :dependencies, :source

    def initialize(root_module, path)
      @root_module = root_module
      @path = path
    end

    def read(precache_sources = [])
      root_module.dsl_class.run(self, precache_sources)
    end

  end
end
