# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "librarian/version"

Gem::Specification.new do |gem|
  gem.name        = "librarian"
  gem.version     = Librarian::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.authors     = ["Jay Feldblum"]
  gem.email       = ["y_feldblum@yahoo.com"]
  gem.homepage    = ""
  gem.summary     = %q{Librarian}
  gem.description = %q{Librarian}

  gem.rubyforge_project = "librarian"

  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "thor", "~> 0.15"
  gem.add_dependency "highline"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "json"
  gem.add_development_dependency "fakefs", "~> 0.4.2"

  gem.add_dependency "chef", ">= 0.10"
  gem.add_dependency "archive-tar-minitar", ">= 0.5.2"

  gem.add_development_dependency "webmock"
end
