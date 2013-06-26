require 'bundler'
require 'rspec/core/rake_task'

module Bundler
  class GemHelper

    def build_gem_with_built_spec
      spec = Gem::Specification.load(spec_path)
      spec_ruby = spec.to_ruby
      original_spec_path = spec_path + ".original"
      FileUtils.mv(spec_path, original_spec_path)
      File.open(spec_path, "wb"){|f| f.write(spec_ruby)}
      build_gem_without_built_spec
    ensure
      FileUtils.mv(original_spec_path, spec_path)
    end

    alias build_gem_without_built_spec build_gem
    alias build_gem build_gem_with_built_spec

  end
end

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new('spec')
task :default => :spec

