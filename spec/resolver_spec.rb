require 'librarian'
require 'librarian/mock'

module Librarian
  describe Resolver do

    before do
      Mock::Source::Mock::Registry.clear!
    end

    context "a simple specfile" do

      it "should work" do
        Mock::Source::Mock::Registry.merge! do
          source 'source-1' do
            spec 'butter' do
              version '1.1'
            end
          end
        end
        spec = Mock::Dsl.run do
          src 'source-1'
          dep 'butter'
        end
        resolver = Resolver.new(Mock)
        manifests = resolver.resolve(spec.source, spec.dependencies)
        resolver.resolved?(spec.dependencies, manifests).should be_true
      end

    end

    context "a specfile with a dep from one src depending on a dep from another src" do

      it "should work" do
        Mock::Source::Mock::Registry.merge! do
          source 'source-1' do
            spec 'butter' do
              version '1.1'
            end
          end
          source 'source-2' do
            spec 'jam' do
              version '1.2' do
                dependency 'butter', '>= 1.0'
              end
            end
          end
        end
        spec = Mock::Dsl.run do
          src 'source-1'
          src 'source-2' do
            dep 'jam'
          end
        end
        resolver = Resolver.new(Mock)
        manifests = resolver.resolve(spec.source, spec.dependencies)
        resolver.resolved?(spec.dependencies, manifests).should be_true
      end

    end

  end
end
