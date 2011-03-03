require 'librarian'
require 'librarian/mock'

module Librarian
  module Mock

    describe Dsl do

      context "a single dependency but no applicable source" do

        it "should not run without any sources" do
          expect do
            Dsl.run do
              dep 'dependency-1'
            end
          end.to raise_error(Dsl::Error)
        end

        it "should not run when a block source is defined but the dependency is outside the block" do
          expect do
            Dsl.run do
              src 'source-1' do end
              dep 'dependency-1'
            end
          end.to raise_error(Dsl::Error)
        end

      end

      context "a simple specfile - a single source, a single dependency, no transitive dependencies" do

        it "should run with a hash source" do
          spec = Dsl.run do
            dep 'dependency-1',
              :src => 'source-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should be_empty
        end

        it "should run with a block hash source" do
          spec = Dsl.run do
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
          spec = Dsl.run do
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
          spec = Dsl.run do
            source :src => 'source-1'
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should_not be_empty
          spec.sources.size.should == 1
          spec.dependencies.first.source.should == spec.sources.first
        end

        it "should run with a default named source" do
          spec = Dsl.run do
            src 'source-1'
            dep 'dependency-1'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'dependency-1'
          spec.dependencies.first.source.name.should == 'source-1'
          spec.sources.should_not be_empty
          spec.sources.size.should == 1
          spec.dependencies.first.source.should == spec.sources.first
        end

      end

    end

  end
end