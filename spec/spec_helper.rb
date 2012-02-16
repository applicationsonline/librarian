Bundler.require(:bdd)

module FakeFSTrigger
  def self.included(base)
    RSpec.configure do |config|
      config.before(:suite) do
        require 'fakefs/spec_helpers'
        config.include ::FakeFS::SpecHelpers
        ::FakeFS.activate!
        puts '  Loaded fakefs/spec_helpers'
      end
      config.after(:each) do
        #FakeFS::FileSystem.clear
      end
      config.after(:suite) do
        ::FakeFS::FileSystem.clear
        ::FakeFS.deactivate!
      end
    end
  end
end

RSpec.configure do |config|
  config.mock_with :rr
  config.include FakeFSTrigger, type: :fakefs
end

