require 'librarian'
require 'librarian/mock'

module Librarian
  describe Lockfile do

    before do
      Mock.registry.clear!
    end

    it "should save" do
      Mock.registry.merge! do
        source 'source-1' do
          spec 'alpha', '1.1'
        end
      end
      spec = Mock::Dsl.run do
        src 'source-1'
        dep 'alpha', '1.1'
      end
      resolver = Resolver.new(Mock)
      manifests = resolver.resolve(spec)
      manifests.should_not be_nil
      lockfile = Lockfile.new(Mock, nil)
      lockfile_text = lockfile.save(manifests)
      lockfile_text.should_not be_nil
    end

    it "should bounce" do
      Mock.registry.merge! do
        source 'source-1' do
          spec 'alpha', '1.1'
        end
      end
      spec = Mock::Dsl.run do
        src 'source-1'
        dep 'alpha', '1.1'
      end
      resolver = Resolver.new(Mock)
      manifests = resolver.resolve(spec)
      manifests.should_not be_nil
      lockfile = Lockfile.new(Mock, nil)
      lockfile_text = lockfile.save(manifests)
      bounced_manifests = lockfile.load(lockfile_text)
      bounced_lockfile_text = lockfile.save(bounced_manifests)
      bounced_lockfile_text.should == lockfile_text
    end

  end
end
