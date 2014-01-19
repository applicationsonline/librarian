require "pathname"
require "tmpdir"

require "support/fakefs"

require 'librarian/resolver'
require 'librarian/spec_change_set'
require 'librarian/mock'

module Librarian
  describe Resolver do
    include ::Support::FakeFS

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

      let(:resolution) { resolver.resolve(spec) }

      specify { expect(resolution).to be_correct }

    end

    context "a specfile with a dep from one src depending on a dep from another src" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.1'
          end
          source 'source-2' do
            spec 'jam', '1.2' do
              dependency 'butter', '>= 1.0'
            end
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          src 'source-2' do
            dep 'jam'
          end
        end
      end

      let(:resolution) { resolver.resolve(spec) }

      specify { expect(resolution).to be_correct }

    end

    context "a specfile with a dep in multiple sources" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
          end
          source 'source-2' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
          end
          source 'source-3' do
            spec 'butter', '1.0'
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          src 'source-2'
          dep 'butter', '>= 1.1'
        end
      end

      it "should have the expected number of sources" do
        expect(spec).to have(2).sources
      end

      let(:resolution) { resolver.resolve(spec) }

      specify { expect(resolution).to be_correct }

      it "should have the manifest from the final source with a matching manifest" do
        manifest = resolution.manifests.find{|m| m.name == "butter"}
        expect(manifest.source.name).to eq "source-2"
      end

    end

    context "a specfile with a dep depending on a nonexistent dep" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'jam', '1.2' do
              dependency 'butter', '>= 1.0'
            end
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          dep 'jam'
        end
      end

      let(:resolution) { resolver.resolve(spec) }

      specify { expect(resolution).to be_nil }

    end

    context "a specfile with conflicting constraints" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
            spec 'jam', '1.2' do
              dependency 'butter', '1.1'
            end
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          dep 'butter', '1.0'
          dep 'jam'
        end
      end

      let(:resolution) { resolver.resolve(spec) }

      specify { expect(resolution).to be_nil }

    end

    context "a specfile with cyclic constraints" do

      before do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0' do
              dependency 'jam', '2.0'
            end
            spec 'jam', '2.0' do
              dependency 'butter', '1.0'
            end
          end
        end
      end

      let(:spec) do
        env.dsl do
          src 'source-1'
          dep 'butter'
        end
      end

      let(:resolution) { resolver.resolve(spec) }

      context "when cyclic resolutions are forbidden" do
        let(:resolver) { env.resolver(:cyclic => false) }

        specify { expect(resolution).to be_nil }
      end

      context "when cyclic resolutions are permitted" do
        let(:resolver) { env.resolver(:cyclic => true) }

        it "should have all the manifests" do
          manifest_names = resolution.manifests.map(&:name).sort
          expect(manifest_names).to be == %w[butter jam]
        end
      end

    end

    context "updating" do

      it "should not work" do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
            spec 'butter', '1.1'
            spec 'jam', '1.2' do
              dependency 'butter'
            end
          end
        end
        first_spec = env.dsl do
          src 'source-1'
          dep 'butter', '1.1'
          dep 'jam'
        end
        first_resolution = resolver.resolve(first_spec)
        expect(first_resolution).to be_correct
        first_manifests = first_resolution.manifests
        first_manifests_index = Hash[first_manifests.map{|m| [m.name, m]}]
        expect(first_manifests_index['butter'].version.to_s).to eq '1.1'

        second_spec = env.dsl do
          src 'source-1'
          dep 'butter', '1.0'
          dep 'jam'
        end
        locked_manifests = ManifestSet.deep_strip(first_manifests, ['butter'])
        second_resolution =resolver.resolve(second_spec, locked_manifests)
        expect(second_resolution).to be_correct
        second_manifests = second_resolution.manifests
        second_manifests_index = Hash[second_manifests.map{|m| [m.name, m]}]
        expect(second_manifests_index['butter'].version.to_s).to eq '1.0'
      end

    end

    context "a change to the spec" do

      it "should work" do
        env.registry :clear => true do
          source 'source-1' do
            spec 'butter', '1.0'
          end
          source 'source-2' do
            spec 'butter', '1.0'
          end
        end
        spec = env.dsl do
          src 'source-1'
          dep 'butter'
        end
        lock = resolver.resolve(spec)
        expect(lock).to be_correct

        spec = env.dsl do
          src 'source-1'
          dep 'butter', :src => 'source-2'
        end
        changes = SpecChangeSet.new(env, spec, lock)
        expect(changes).to_not be_same
        manifests = ManifestSet.new(changes.analyze).to_hash
        expect(manifests).to_not have_key('butter')
        lock = resolver.resolve(spec, changes.analyze)
        expect(lock).to be_correct
        expect(lock.manifests.map{|m| m.name}).to include('butter')
        manifest = lock.manifests.find{|m| m.name == 'butter'}
        expect(manifest).to_not be_nil
        expect(manifest.source.name).to eq 'source-2'
      end

    end

    context "a pathname to a simple specfile" do
      let(:pwd) { Pathname(Dir.tmpdir) }
      let(:specfile_path) { pwd + "Mockfile" }
      before { FileUtils.mkpath(pwd) }

      def write!(path, text)
        Pathname(path).open("wb"){|f| f.write(text)}
      end

      it "loads the specfile with the __FILE__" do
        write! specfile_path, "src __FILE__"
        spec = env.dsl(specfile_path)
        expect(spec.sources).to have(1).item
        source = spec.sources.first
        expect(source.name).to eq specfile_path.to_s
      end

    end

  end
end
