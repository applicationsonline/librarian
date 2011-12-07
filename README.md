Librarian
=========

A tool to resolve recursively a set of specifications and fetch and install the fully resolved specifications.

Librarian::Mock
---------------

An adapter for Librarian for unit testing the general features.
The mock source is in-process and in-memory and does not touch the filesystem or the network.

Librarian::Chef
---------------

An adapter for Librarian applying to Chef cookbooks in a Chef Repository. When used with Chef, Librarian is really for pulling in the 50 or so finished third-party cookbooks that you're using, not the 1 or 2 cookbooks you're actively working on.

## Install librarian:

    $ gem install librarian


__Make sure your cookbooks directory is gitignored__

    $ cd ~/path/to/chef-repo
    $ git rm -r cookbooks # if the directory is present
    $ echo cookbooks >> .gitignore
    $ echo tmp >> .gitignore

Note that librarian *takes over* your cookbooks directory
  and manages it for you based on your Cheffile. Your
  Cheffile becomes the authoritative source for what
  cookbooks you have, rather than the directories in your
  cookbooks directory.

__Make a Cheffile__

    $ librarian-chef init

__Add dependencies and their sources to Cheffile__

    $ cat Cheffile
        site 'http://community.opscode.com/api/v1'
        cookbook 'ntp'
        cookbook 'timezone', '0.0.1'
        cookbook 'rvm',
          :git => 'https://github.com/fnichol/chef-rvm',
          :ref => 'v0.7.1'

__install dependencies into ./cookbooks__

    $ librarian-chef install [--clean] [--verbose]

__Check your Cheffile.lock into version control__

    $ git add Cheffile.lock
    $ git commit -m "I want these particular versions of these particular cookbooks from these particular."

__Update your cheffile with new/changed/removed constraints/sources/dependencies__

    $ cat Cheffile
        site 'http://community.opscode.com/api/v1'
        cookbook 'ntp'
        cookbook 'timezone', '0.0.1'
        cookbook 'rvm',
          :git => 'https://github.com/fnichol/chef-rvm',
          :ref => 'v0.7.1'
        cookbook 'monit' # new!
    $ git diff Cheffile
    $ librarian-chef install [--verbose]
    $ git diff Cheffile.lock
    $ git add Cheffile
    $ git add Cheffile.lock
    $ git commit -m "I also want these additional cookbooks."

__Update the version of a dependency__

    $ librarian-chef update ntp timezone monit [--verbose]
    $ git diff Cheffile.lock
    $ git add Cheffile.lock
    $ git commit -m "I want updated versions of these cookbooks."

__Push your changes to the git repository__

    $ git push origin master

__Upload the cookbooks to your chef-server__

    $ knife cookbook upload --all

You should `.gitignore` your `./cookbooks` directory.
If you are manually tracking/vendoring outside cookbooks within the repository,
  put them in another directory such as `./cookbooks-sources` and use the `:path` source.
  You should typically not need to do this.

You can integrate your `knife.rb` with Librarian. Stick the following in your `knife.rb`:

    require 'librarian/chef/integration/knife'
    cookbook_path Librarian::Chef.install_path, "chef-repo/site-cookbooks"

In the above, make sure *not* to include the path to your `chef-repo/cookbooks`. If you
  have additional cookbooks directories in your chef-repo that you use for `:path`-sourced
  cookbooks in your `Cheffile`, make sure *not* to include the paths to those additional
  cookbooks directories either in your chef-repo. Since your `chef-repo/site-cookbooks`
  directory is for overrides (monkey-patches) to external cookbooks, and since you should
  not have any `:path`-sourced cookbooks in your `Cheffile` sourced from that directory,
  you still need to include your `chef-repo/site-cookbooks` directory in the above list.

What this integration does is when you use `knife`, it will enforce that your `Cheffile`
  and `Cheffile.lock` are in sync. When you `knife cookbook upload`, it will be sure to
  upload the same cookbook as is in your `Cheffile.lock`, regardless of what you've done
  to your `chef-repo/cookbooks` directory.

License
-------

Written by Jay Feldblum.

Copyright (c) 2011 ApplicationsOnline, LLC.

Released under the terms of the MIT License.
