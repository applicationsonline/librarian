require 'librarian/specfile/dsl'
require 'librarian/chef/cookbook'
require 'librarian/chef/source'

module Librarian
  module Chef
    class Dsl < Specfile::Dsl
      dependency :cookbook => Cookbook

      source :site => Source::Site
      source :git => Source::Git
      source :path => Source::Path
    end
  end
end
