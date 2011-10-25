## 0.0.9

* \#11 Fixes a problem where, if the repo is in a path where a component has a space, attempting to resolve a
    site-sourced dependency fails.

## 0.0.8

* A `version` task.

* A change log.

* \#10 Fixes the problem with bouncing the lockfile when updating, when using a git source with the default ref.

## 0.0.7

* \#8 Add highline temporarily as a runtime dependency of `librarian` (@fnichol).
  When the project is split into `librarian` and `librarian-chef`, the `chef` runtime dependency will
    be moved to `librarian-chef`. If the project is further split into a knife plugin, the dependency
    will be moved there.

## 0.0.6

* \#7 Show a better error message when a cookbook is missing the required metadata file.

* Miscellaneous bugfixes.

## 0.0.5

* \#4 An `init` task for `librarian-chef`.
  This task creates a nearly-blank `Cheffile` with just the default Opscode Community Site source.

* Automatically create the `cookbooks` directory, if it's missing, when running the `install` task.

* \#3 Add `chef` temporarily as a runtime dependency of `librarian` (@fnichol).
  When the project is split into `librarian` and `librarian-chef`, the `chef` runtime dependency will
    be moved to `librarian-chef`.

## 0.0.4

* A simple knife integration.
  This integration allows you to specify a `librarian-chef`-managed tempdir as a `cookbook_path`.
  This is useful to force knife only to upload the exact cookbooks that `librarian-chef` knows
    about, rather than whatever happens to be found in the `cookbooks` directory.

## 0.0.3

* Miscellaneous bugfixes.

## 0.0.2

* An optional `:path` attribute for `:git` sources.
  This allows you to specify exactly where within a git repository a given cookbook is to be found.

* A full example of a Cheffile and its usage in the readme.

## 0.0.1

* Initial release.
