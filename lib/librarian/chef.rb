require 'librarian/specfile'
require 'librarian/source'
require 'librarian/chef/cookbook'
require 'librarian/chef/source'

module Librarian

  class Specfile
    class Dsl

      dependency :cookbook => Librarian::Chef::Cookbook

      source :site => Librarian::Chef::Source::Site
      source :git => Librarian::Source::Git
      source :path => Librarian::Source::Path

    end
  end

  self.specfile_name = 'Cheffile'

  def self.install_path
    project_path.join('cookbooks')
  end

end
