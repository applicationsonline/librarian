Librarian [![Build Status](https://secure.travis-ci.org/applicationsonline/librarian.png)](http://travis-ci.org/applicationsonline/librarian) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/applicationsonline/librarian)
=========

Librarian is a framework for writing bundlers, which are tools that resolve,
fetch, install, and isolate a project's dependencies, in Ruby.

A bundler written with Librarian will expect you to provide a specfile listing
your project's declared dependencies, including any version constraints and
including the upstream sources for finding them. Librarian can resolve the spec,
write a lockfile listing the full resolution, fetch the resolved dependencies,
install them, and isolate them in your project.

A bundler written with Librarian will be similar in kind to [Bundler](http://gembundler.com),
the bundler for Ruby gems that many modern Rails applications use.

Implementations
---------------

- [Librarian-Chef](https://github.com/patcon/librarian-chef)
- [Librarian-Puppet](https://github.com/rodjek/librarian-puppet)

How to Contribute
-----------------

### Running the tests

    $ rspec spec

You will probably need some way to isolate gems. Librarian provides a `Gemfile`,
so if you want to use bundler, you can prepare the directory with the usual
`bundle install` and run each command prefixed with the usual `bundle exec`, as:

    $ bundle install
    $ bundle exec rspec spec

### Installing locally

    $ rake install

You should typically not need to install locally, if you are simply trying to
patch a bug and test the result on a test case. Instead of installing locally,
you are probably better served by:

    $ cd $PATH_TO_INFRASTRUCTURE_REPO
    $ $PATH_TO_LIBRARIAN_CHECKOUT/bin/librarian-chef install [--verbose]

### Reporting Issues

Please include relevant `Cheffile` and `Cheffile.lock` files. Please run the
`librarian-chef` commands in verbose mode by using the `--verbose` flag, and
include the verbose output in the bug report as well.

License
-------

Written by Jay Feldblum.

Copyright (c) 2011-2012 ApplicationsOnline, LLC.

Released under the terms of the MIT License. For further information, please see
the file `MIT-LICENSE`.
