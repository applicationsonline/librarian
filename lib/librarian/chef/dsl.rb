require 'librarian/dsl'
require 'librarian/chef/particularity'
require 'librarian/chef/source'

module Librarian
  module Chef
    class Dsl < Librarian::Dsl

      include Particularity

      dependency :cookbook

      source :site => Source::Site
      source :git => Source::Git
      source :path => Source::Path
    end
  end
end
