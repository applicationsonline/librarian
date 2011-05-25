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
      resolution = Mock.resolver.resolve(spec)
      resolution.should be_correct
      lockfile = Mock.ephemeral_lockfile
      lockfile_text = lockfile.save(resolution)
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
      resolution = Mock.resolver.resolve(spec)
      resolution.should be_correct
      lockfile = Mock.ephemeral_lockfile
      lockfile_text = lockfile.save(resolution)
      bounced_resolution = lockfile.load(lockfile_text)
      bounced_lockfile_text = lockfile.save(bounced_resolution)
      bounced_lockfile_text.should == lockfile_text
    end

  end
end
