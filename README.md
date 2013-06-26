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

How to Contribute
-----------------

### Running the tests

Ensure the gem dependencies are installed:

    $ bundle

Run the tests with the default rake task:

    $ [bundle exec] rake
    
or directly with the rspec command:

    $ [bundle exec] rspec spec

### Installing locally

Ensure the gem dependencies are installed:

    $ bundle

Install from the repository:

    $ [bundle exec] rake install

### Reporting Issues

Please include a reproducible test case.

License
-------

Written by Jay Feldblum.

Copyright (c) 2011-2013 ApplicationsOnline, LLC.

Released under the terms of the MIT License. For further information, please see
the file `LICENSE.txt`.
