require 'librarian/resolver'
require 'librarian/mock'

module Librarian
  describe Resolver do

    context "a simple specfile" do

      it "should work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.1'
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'butter'
        end
        resolver = Mock.resolver
        resolution = resolver.resolve(spec)
        resolution.should be_correct
      end

    end

    context "a specfile with a dep from one src depending on a dep from another src" do

      it "should work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.1'
          end
          source 'source-2' do
            spec 'jam', '1.2' do
              dependency 'butter', '>= 1.0'
            end
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          src 'source-2' do
            dep 'jam'
          end
        end
        resolver = Mock.resolver
        resolution = resolver.resolve(spec)
        resolution.should be_correct
      end

    end

    context "a specfile with a dep depending on a nonexistent dep" do

      it "should not work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'jam', '1.2' do
              dependency 'butter', '>= 1.0'
            end
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'jam'
        end
        resolver = Mock.resolver
        resolution = resolver.resolve(spec)
        resolution.should_not be_correct
      end

    end

    context "a specfile with conflicting constraints" do

      it "should not work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
            spec 'jam', '1.2' do
              dependency 'butter', '1.1'
            end
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'butter', '1.0'
          dep 'jam'
        end
        resolver = Mock.resolver
        resolution = resolver.resolve(spec)
        resolution.should_not be_correct
      end

    end

    context "updating" do

      it "should not work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
            spec 'jam', '1.2' do
              dependency 'butter'
            end
          end
        end
        first_spec = Mock.dsl do
          src 'source-1'
          dep 'butter', '1.1'
          dep 'jam'
        end
        first_resolution = Mock.resolver.resolve(first_spec)
        first_resolution.should be_correct
        first_manifests = first_resolution.manifests
        first_manifests_index = Hash[first_manifests.map{|m| [m.name, m]}]
        first_manifests_index['butter'].version.to_s.should == '1.1'

        second_spec = Mock.dsl do
          src 'source-1'
          dep 'butter', '1.0'
          dep 'jam'
        end
        locked_manifests = ManifestSet.deep_strip(first_manifests, ['butter'])
        second_resolution = Mock.resolver.resolve(second_spec, locked_manifests)
        second_resolution.should be_correct
        second_manifests = second_resolution.manifests
        second_manifests_index = Hash[second_manifests.map{|m| [m.name, m]}]
        second_manifests_index['butter'].version.to_s.should == '1.0'
      end

    end

    context "a change to the spec" do

      it "should work" do
        Mock.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
          end
          source 'source-2' do
            spec 'butter', '1.0'
          end
        end
        spec = Mock.dsl do
          src 'source-1'
          dep 'butter'
        end
        lock = Mock.resolver.resolve(spec)
        lock.should be_correct

        spec = Mock.dsl do
          src 'source-1'
          dep 'butter', :src => 'source-2'
        end
        changes = Mock.spec_change_set(spec, lock)
        changes.should_not be_same
        manifests = ManifestSet.new(changes.analyze).to_hash
        manifests.should_not have_key('butter')
        lock = Mock.resolver.resolve(spec, changes.analyze)
        lock.should be_correct
        lock.manifests.map{|m| m.name}.should include('butter')
        manifest = lock.manifests.find{|m| m.name == 'butter'}
        manifest.should_not be_nil
        manifest.source.name.should == 'source-2'
      end

    end

  end
end
