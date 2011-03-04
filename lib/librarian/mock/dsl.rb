require 'librarian/dsl'
require 'librarian/mock/source'

module Librarian
  module Mock
    class Dsl < Librarian::Dsl
      dependency :dep

      source :src => Source::Mock
    end
  end
end
