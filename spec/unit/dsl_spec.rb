require 'librarian'
require 'librarian/mock'

module Librarian
  module Mock

    describe Dsl do

      let(:env) { Environment.new }

      context "a single source and a single dependency with a blank name" do
        it "should not not run with a blank name" do
          expect do
            env.dsl do
              src 'source-1'
              dep ''
            end
          end.to raise_error(ArgumentError, %{name ("") must be sensible})
        end
      end

      context "a simple specfile - a single source, a single dependency, no transitive dependencies" do

        it "should run with a hash source" do
          spec = env.dsl do
            dep 'dependency-1',
              :src => 'source-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-1'
          expect(spec.sources).to be_empty
        end

        it "should run with a shortcut source" do
          spec = env.dsl do
            dep 'dependency-1',
              :source => :a
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-a'
          expect(spec.sources).to be_empty
        end

        it "should run with a block hash source" do
          spec = env.dsl do
            source :src => 'source-1' do
              dep 'dependency-1'
            end
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-1'
          expect(spec.sources).to be_empty
        end

        it "should run with a block named source" do
          spec = env.dsl do
            src 'source-1' do
              dep 'dependency-1'
            end
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-1'
          expect(spec.sources).to be_empty
        end

        it "should run with a default hash source" do
          spec = env.dsl do
            source :src => 'source-1'
            dep 'dependency-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-1'
          expect(spec.sources).to_not be_empty
          expect(spec.dependencies.first.source).to eq spec.sources.first
        end

        it "should run with a default named source" do
          spec = env.dsl do
            src 'source-1'
            dep 'dependency-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-1'
          expect(spec.sources).to_not be_empty
          expect(spec.dependencies.first.source).to eq spec.sources.first
        end

        it "should run with a default shortcut source" do
          spec = env.dsl do
            source :a
            dep 'dependency-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-a'
          expect(spec.sources).to_not be_empty
          expect(spec.dependencies.first.source).to eq spec.sources.first
        end

        it "should run with a shortcut source hash definition" do
          spec = env.dsl do
            source :b, :src => 'source-b'
            dep 'dependency-1', :source => :b
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-b'
          expect(spec.sources).to be_empty
        end

        it "should run with a shortcut source block definition" do
          spec = env.dsl do
            source :b, proc { src 'source-b' }
            dep 'dependency-1', :source => :b
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-b'
          expect(spec.sources).to be_empty
        end

        it "should run with a default shortcut source hash definition" do
          spec = env.dsl do
            source :b, :src => 'source-b'
            source :b
            dep 'dependency-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-b'
          expect(spec.sources).to_not be_empty
          expect(spec.sources.first.name).to eq 'source-b'
        end

        it "should run with a default shortcut source block definition" do
          spec = env.dsl do
            source :b, proc { src 'source-b' }
            source :b
            dep 'dependency-1'
          end
          expect(spec.dependencies).to_not be_empty
          expect(spec.dependencies.first.name).to eq 'dependency-1'
          expect(spec.dependencies.first.source.name).to eq 'source-b'
          expect(spec.sources).to_not be_empty
          expect(spec.sources.first.name).to eq 'source-b'
        end

      end

      context "validating source options" do

        it "should raise when given unrecognized optiosn options" do
          expect do
            env.dsl do
              dep 'dependency-1',
                :src => 'source-1',
                :huh => 'yikes'
            end
          end.to raise_error(Error, %{unrecognized options: huh})
        end

      end

    end

  end
end