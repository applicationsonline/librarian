Librarian
=========

A tool to resolve recursively a set of specifications and fetch and install the fully resolved specifications.

Librarian::Mock
---------------

An adapter for Librarian for unit testing the general features.
The mock source is in-process and in-memory and does not touch the filesystem or the network.

Librarian::Chef
---------------

An adapter for Librarian applying to Chef cookbooks in a Chef Repository.

Usage:

    $ cd ~/path/to/chef-repo
    # put dependencies and their sources into ./Cheffile

    # resolve dependencies:
    $ librarian-chef resolve [--clean] [--verbose]

    # install dependencies into ./cookbooks
    $ librarian-chef install [--clean] [--verbose]

You should `.gitignore` your `./cookbooks` directory.
If you are manually tracking/vendoring outside cookbooks within the repository,
  put them in another directory such as `./cookbooks-sources` and use the `:path` source.
  You should typically not need to do this.
