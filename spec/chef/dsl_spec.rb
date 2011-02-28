require 'librarian'
require 'librarian/chef'

module Librarian
  module Chef

    describe Dsl do

      context "a single dependency but no applicable source" do

        it "should not run without any sources" do
          expect do
            Dsl.run do
              cookbook 'apt'
            end
          end.to raise_error(Dsl::Error)
        end

        it "should not run when a block source is defined but the dependency is outside the block" do
          expect do
            Dsl.run do
              git 'https://github.com/opscode/cookbooks.git' do
              end
              cookbook 'apt'
            end
          end.to raise_error(Dsl::Error)
        end

      end

      context "a simple specfile - a single source, a single dependency, no transitive dependencies" do

        it "should run with a hash source" do
          spec = Dsl.run do
            cookbook 'apt',
              :git => 'https://github.com/opscode/cookbooks.git'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'apt'
          spec.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
          spec.sources.should be_empty
        end

        it "should run with a block hash source" do
          spec = Dsl.run do
            source :git => 'https://github.com/opscode/cookbooks.git' do
              cookbook 'apt'
            end
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'apt'
          spec.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
          spec.sources.should be_empty
        end

        it "should run with a block named source" do
          spec = Dsl.run do
            git 'https://github.com/opscode/cookbooks.git' do
              cookbook 'apt'
            end
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'apt'
          spec.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
          spec.sources.should be_empty
        end

        it "should run with a default hash source" do
          spec = Dsl.run do
            source :git => 'https://github.com/opscode/cookbooks.git'
            cookbook 'apt'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'apt'
          spec.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
          spec.sources.should_not be_empty
          spec.sources.size.should == 1
          spec.dependencies.first.source.should == spec.sources.first
        end

        it "should run with a default named source" do
          spec = Dsl.run do
            git 'https://github.com/opscode/cookbooks.git'
            cookbook 'apt'
          end
          spec.dependencies.should_not be_empty
          spec.dependencies.first.name.should == 'apt'
          spec.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
          spec.sources.should_not be_empty
          spec.sources.size.should == 1
          spec.dependencies.first.source.should == spec.sources.first
        end

      end

    end

  end
end