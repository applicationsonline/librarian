# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "librarian"
  gem.version       = File.read(File.expand_path("../VERSION", __FILE__))
  gem.authors       = ["Jay Feldblum"]
  gem.email         = ["y_feldblum@yahoo.com"]
  gem.summary       = %q{A Framework for Bundlers.}
  gem.description   = %q{A Framework for Bundlers.}
  gem.homepage      = "https://github.com/applicationsonline/librarian"
  gem.license       = "MIT"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency "thor", "~> 0.15"
  gem.add_dependency "highline"

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "json"
  gem.add_development_dependency "fakefs", "~> 0.4.2"
end
