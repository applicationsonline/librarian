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
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should be_empty
        end

        it "should run with a shortcut source" do
          spec = env.dsl do
            dep 'dependency-1',
              :source => :a
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-a'
          spec.sources.should be_empty
        end

        it "should run with a block hash source" do
          spec = env.dsl do
            source :src => 'source-1' do
              dep 'dependency-1'
            end
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should be_empty
        end

        it "should run with a block named source" do
          spec = env.dsl do
            src 'source-1' do
              dep 'dependency-1'
            end
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should be_empty
        end

        it "should run with a default hash source" do
          spec = env.dsl do
            source :src => 'source-1'
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should_not be_empty
          spec.dependencies.first.source.should == spec.sources.first
        end

        it "should run with a default named source" do
          spec = env.dsl do
            src 'source-1'
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should_not be_empty
          spec.dependencies.first.source.should == spec.sources.first
        end

        it "should run with a default shortcut source" do
          spec = env.dsl do
            source :a
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-a'
          spec.sources.should_not be_empty
          spec.dependencies.first.source.should == spec.sources.first
        end

        it "should run with a shortcut source hash definition" do
          spec = env.dsl do
            source :b, :src => 'source-b'
            dep 'dependency-1', :source => :b
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-b'
          spec.sources.should be_empty
        end

        it "should run with a shortcut source block definition" do
          spec = env.dsl do
            source :b, proc { src 'source-b' }
            dep 'dependency-1', :source => :b
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-b'
          spec.sources.should be_empty
        end

        it "should run with a default shortcut source hash definition" do
          spec = env.dsl do
            source :b, :src => 'source-b'
            source :b
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-b'
          spec.sources.should_not be_empty
          spec.sources.first.name.should == 'source-b'
        end

        it "should run with a default shortcut source block definition" do
          spec = env.dsl do
            source :b, proc { src 'source-b' }
            source :b
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-b'
          spec.sources.should_not be_empty
          spec.sources.first.name.should == 'source-b'
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