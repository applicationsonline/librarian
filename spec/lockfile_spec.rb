require 'librarian'
require 'librarian/mock'

module Librarian
  describe Lockfile do

    it "should save" do
      Mock.registry :clear => true do
        source 'source-1' do
          spec 'alpha', '1.1'
        end
      end
      spec = Mock.dsl do
        src 'source-1'
        dep 'alpha', '1.1'
      end
      manifests = Mock.resolver.resolve(spec)
      manifests.should_not be_nil
      lockfile = Lockfile.new(Mock, nil)
      lockfile_text = lockfile.save(Resolution.new(spec.dependencies, manifests))
      lockfile_text.should_not be_nil
    end

    it "should bounce" do
      Mock.registry :clear => true do
        source 'source-1' do
          spec 'alpha', '1.1'
        end
      end
      spec = Mock.dsl do
        src 'source-1'
        dep 'alpha', '1.1'
      end
      manifests = Mock.resolver.resolve(spec)
      manifests.should_not be_nil
      lockfile = Lockfile.new(Mock, nil)
      lockfile_text = lockfile.save(Resolution.new(spec.dependencies, manifests))
      bounced_resolution = lockfile.load(lockfile_text)
      bounced_lockfile_text = lockfile.save(bounced_resolution)
      bounced_lockfile_text.should == lockfile_text
    end

  end
end
