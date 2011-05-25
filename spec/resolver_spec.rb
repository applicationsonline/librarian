require 'librarian'
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
        manifests = resolver.resolve(spec)
        resolver.resolved?(spec.dependencies, manifests).should be_true
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
        manifests = resolver.resolve(spec)
        resolver.resolved?(spec.dependencies, manifests).should be_true
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
        manifests = resolver.resolve(spec)
        resolver.resolved?(spec.dependencies, manifests).should be_false
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
        manifests = resolver.resolve(spec)
        resolver.resolved?(spec.dependencies, manifests).should be_false
      end

    end

  end
end
