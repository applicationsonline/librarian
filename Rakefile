require 'bundler'
Bundler::GemHelper.install_tasks

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)

  require 'cucumber/rake/task'
  Cucumber::Rake::Task.new(:features)

  task :default => [:spec, :features]
rescue LoadError
end
