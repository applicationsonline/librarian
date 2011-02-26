require 'librarian'
require 'librarian/chef'

module Librarian
  class Specfile

    describe Dsl do

      context "simple" do

        it "should run" do
          dsl_target = Dsl.run do
            cookbook 'apt',
              :git => 'https://github.com/opscode/cookbooks.git'
          end
          dsl_target.dependencies.should_not be_empty
          dsl_target.dependencies.first.name.should == 'apt'
          dsl_target.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
        end

        it "should run with a hash block source" do
          dsl_target = Dsl.run do
            source :git => 'https://github.com/opscode/cookbooks.git' do
              cookbook 'apt'
            end
          end
          dsl_target.dependencies.should_not be_empty
          dsl_target.dependencies.first.name.should == 'apt'
          dsl_target.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
        end

        it "should run with a named block source" do
          dsl_target = Dsl.run do
            git 'https://github.com/opscode/cookbooks.git' do
              cookbook 'apt'
            end
          end
          dsl_target.dependencies.should_not be_empty
          dsl_target.dependencies.first.name.should == 'apt'
          dsl_target.dependencies.first.source.uri.should =~ /opscode\/cookbooks/
        end

      end

    end

  end
end