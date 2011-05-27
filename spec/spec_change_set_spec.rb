require 'librarian'
require 'librarian/mock'

module Librarian
  describe SpecChangeSet do

    context "a simple root removal" do

      it "should work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'jam', '1.0'
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'butter'
          dep 'jam'
        end
        lock = Mock.resolver.resolve(spec)
        lock.should be_correct

        spec = Mock.dsl do
          src 'source-1'
          dep 'jam'
        end
        changes = Mock.spec_change_set(spec, lock)
        changes.should_not be_same

        manifests = ManifestSet.new(changes.analyze).to_hash
        manifests.should have_key('jam')
        manifests.should_not have_key('butter')
      end

    end

    context "a simple root add" do

      it "should work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'jam', '1.0'
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'jam'
        end
        lock = Mock.resolver.resolve(spec)
        lock.should be_correct

        spec = Mock.dsl do
          src 'source-1'
          dep 'butter'
          dep 'jam'
        end
        changes = Mock.spec_change_set(spec, lock)
        changes.should_not be_same
        manifests = ManifestSet.new(changes.analyze).to_hash
        manifests.should have_key('jam')
        manifests.should_not have_key('butter')
      end

    end

    context "a simple root change" do

      context "when the change is consistent" do

        it "should work" do
          Mock.registry :clear => true do
            source 'source-1' do
              spec 'butter', '1.0'
              spec 'jam', '1.0'
              spec 'jam', '1.1'
            end
          end
          spec = Mock.dsl do
            src 'source-1'
            dep 'butter'
            dep 'jam', '= 1.1'
          end
          lock = Mock.resolver.resolve(spec)
          lock.should be_correct

          spec = Mock.dsl do
            src 'source-1'
            dep 'butter'
            dep 'jam', '>= 1.0'
          end
          changes = Mock.spec_change_set(spec, lock)
          changes.should_not be_same
          manifests = ManifestSet.new(changes.analyze).to_hash
          manifests.should have_key('butter')
          manifests.should have_key('jam')
        end

      end

      context "when the change is inconsistent" do

        it "should work" do
          Mock.registry :clear => true do
            source 'source-1' do
              spec 'butter', '1.0'
              spec 'jam', '1.0'
              spec 'jam', '1.1'
            end
          end
          spec = Mock.dsl do
            src 'source-1'
            dep 'butter'
            dep 'jam', '= 1.0'
          end
          lock = Mock.resolver.resolve(spec)
          lock.should be_correct

          spec = Mock.dsl do
            src 'source-1'
            dep 'butter'
            dep 'jam', '>= 1.1'
          end
          changes = Mock.spec_change_set(spec, lock)
          changes.should_not be_same
          manifests = ManifestSet.new(changes.analyze).to_hash
          manifests.should have_key('butter')
          manifests.should_not have_key('jam')
        end

      end

    end

  end
end
