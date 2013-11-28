require "librarian/environment"

require "support/with_env_macro"

module Librarian
  describe Environment do
    include ::Support::WithEnvMacro

    let(:env) { described_class.new }

    describe "#adapter_module" do
      specify { expect(env.adapter_module).to be nil }
    end

    describe "#adapter_name" do
      specify { expect(env.adapter_name).to be nil }
    end

    describe "#adapter_version" do
      specify { expect(env.adapter_version).to be nil }
    end

    describe "computing the home" do

      context "with the HOME env var" do
        with_env "HOME" => "/path/to/home"

        it "finds the home" do
          env.stub(:adapter_name).and_return("cat")
          expect(env.config_db.underlying_home.to_s).to eq "/path/to/home"
        end
      end

      context "without the HOME env var" do
        let!(:real_home) { File.expand_path("~") }
        with_env "HOME" => nil

        it "finds the home" do
          env.stub(:adapter_name).and_return("cat")
          expect(env.config_db.underlying_home.to_s).to eq real_home
        end
      end

    end

    describe "#http_proxy_uri" do

      context "sanity" do
        with_env  "http_proxy" => nil

        it "should have a nil http proxy uri" do
          expect(env.http_proxy_uri).to be_nil
        end
      end

      context "with a complex proxy" do
        with_env  "http_proxy" => "admin:secret@example.com"

        it "should have the expcted http proxy uri" do
          expect(env.http_proxy_uri).to eq URI("http://admin:secret@example.com")
        end

        it "should have the expected host" do
          expect(env.http_proxy_uri.host).to eq "example.com"
        end

        it "should have the expected user" do
          expect(env.http_proxy_uri.user).to eq "admin"
        end

        it "should have the expected password" do
          expect(env.http_proxy_uri.password).to eq "secret"
        end
      end

      context "with a split proxy" do
        with_env  "http_proxy" => "example.com",
                  "http_proxy_user" => "admin",
                  "http_proxy_pass" => "secret"

        it "should have the expcted http proxy uri" do
          expect(env.http_proxy_uri).to eq URI("http://admin:secret@example.com")
        end
      end

    end

    describe "#net_http_class" do
      let(:proxied_host) { "www.example.com" }
      context "sanity" do
        with_env  "http_proxy" => nil

        it "should have the normal class" do
          expect(env.net_http_class(proxied_host)).to be Net::HTTP
        end

        it "should not be marked as a proxy class" do
          expect(env.net_http_class(proxied_host)).to_not be_proxy_class
        end
      end

      context "with a complex proxy" do
        with_env  "http_proxy" => "admin:secret@example.com"

        it "should not by marked as a proxy class for localhost" do
          expect(env.net_http_class('localhost')).to_not be_proxy_class
        end
        it "should not have the normal class" do
          expect(env.net_http_class(proxied_host)).to_not be Net::HTTP
        end

        it "should have a subclass the normal class" do
          expect(env.net_http_class(proxied_host)).to be < Net::HTTP
        end

        it "should be marked as a proxy class" do
          expect(env.net_http_class(proxied_host)).to be_proxy_class
        end

        it "should have the expected proxy attributes" do
          http = env.net_http_class(proxied_host).new("www.kernel.org")
          expected_attributes = {
            "host" => env.http_proxy_uri.host,
            "port" => env.http_proxy_uri.port,
            "user" => env.http_proxy_uri.user,
            "pass" => env.http_proxy_uri.password
          }
          actual_attributes = {
            "host" => http.proxy_address,
            "port" => http.proxy_port,
            "user" => http.proxy_user,
            "pass" => http.proxy_pass,
          }

          expect(actual_attributes).to eq expected_attributes
        end

      end

      context "with an excluded host" do
        with_env  "http_proxy" => "admin:secret@example.com",
                  "no_proxy" => "no.proxy.com, noproxy.com"

        context "with an exact match" do
          let(:proxied_host) { "noproxy.com" }

          it "should have the normal class" do
            expect(env.net_http_class(proxied_host)).to be Net::HTTP
          end

          it "should not be marked as a proxy class" do
            expect(env.net_http_class(proxied_host)).to_not be_proxy_class
          end
        end

        context "with a subdomain match" do
          let(:proxied_host) { "www.noproxy.com" }

          it "should have the normal class" do
            expect(env.net_http_class(proxied_host)).to be Net::HTTP
          end

          it "should not be marked as a proxy class" do
            expect(env.net_http_class(proxied_host)).to_not be_proxy_class
          end
        end

        context "with localhost" do
          let(:proxied_host) { "localhost" }

          it "should have the normal class" do
            expect(env.net_http_class(proxied_host)).to be Net::HTTP
          end

          it "should not be marked as a proxy class" do
            expect(env.net_http_class(proxied_host)).to_not be_proxy_class
          end
        end

        context "with 127.0.0.1" do
          let(:proxied_host) { "127.0.0.1" }

          it "should have the normal class" do
            expect(env.net_http_class(proxied_host)).to be Net::HTTP
          end

          it "should not be marked as a proxy class" do
            expect(env.net_http_class(proxied_host)).to_not be_proxy_class
          end
        end

        context "with a mismatch" do
          let(:proxied_host) { "www.example.com" }

          it "should have a subclass the normal class" do
            expect(env.net_http_class(proxied_host)).to be < Net::HTTP
          end

          it "should be marked as a proxy class" do
            expect(env.net_http_class(proxied_host)).to be_proxy_class
          end
        end

      end

    end

  end
end
