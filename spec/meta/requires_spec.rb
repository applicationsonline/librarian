require 'pathname'
require 'open3'

describe 'Meta' do
  describe 'Requires', :slow => true do

    root_path = Pathname.new('../../..').expand_path(__FILE__)

    Pathname.glob(root_path.join('lib/**/*.rb')).sort.each do |path|

      it "require '#{path.relative_path_from(root_path.join('lib'))}'" do
        script = <<-SCRIPT
          lib = File.expand_path(%{lib}, %{#{root_path}})
          $:.unshift(lib) unless $:.include?(lib)
          require %{#{path}}
        SCRIPT
        cmd = <<-CMD
          ruby -e '#{script}'
        CMD
        err = Open3.popen3(cmd) { |i, o, e, t| e.read }
        raise Exception, err if err != ''
      end

    end

  end
end
