module Librarian
  class Specfile

    attr_accessor :environment, :path
    private :environment=, :path=

    def initialize(environment, path)
      self.environment = environment
      self.path = path
    end

    def read(precache_sources = [])
      environment.dsl(path.read, precache_sources)
    end

  end
end
