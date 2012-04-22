require "librarian/resolver/explicit_implementation"
require "librarian/mock"

module Librarian
  describe Resolver::ExplicitImplementation do

    let(:env) { Mock::Environment.new }
    let(:resolver) { env.resolver }

    context "a simple specfile" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.1'
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          dep 'butter'
        end
      end

      let(:impl) { described_class.new(resolver, spec) }
      let(:manifests) { impl.resolve(spec.dependencies) }
      let(:resolution) { Resolution.new(spec.dependencies, manifests) }

      specify { resolution.should be_correct }

    end

  end
end
