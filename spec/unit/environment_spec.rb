require "librarian/environment"

require "support/with_env_macro"

module Librarian
  describe Environment do
    include WithEnvMacro

    let(:env) { described_class.new }

    describe "#http_proxy_uri" do

      context "sanity" do
        with_env  "http_proxy" => nil

        it "should have a nil http proxy uri" do
          env.http_proxy_uri.should be_nil
        end
      end

      context "with a complex proxy" do
        with_env  "http_proxy" => "admin:secret@example.com"

        it "should have the expcted http proxy uri" do
          env.http_proxy_uri.should == URI("http://admin:secret@example.com")
        end

        it "should have the expected host" do
          env.http_proxy_uri.host.should == "example.com"
        end

        it "should have the expected user" do
          env.http_proxy_uri.user.should == "admin"
        end

        it "should have the expected password" do
          env.http_proxy_uri.password.should == "secret"
        end
      end

      context "with a split proxy" do
        with_env  "http_proxy" => "example.com",
                  "http_proxy_user" => "admin",
                  "http_proxy_pass" => "secret"

        it "should have the expcted http proxy uri" do
          env.http_proxy_uri.should == URI("http://admin:secret@example.com")
        end
      end

    end
    describe "no_proxy?" do
      context "sanity" do
        with_env "no_proxy" => nil
        it "should by true for localhost" do
          env.no_proxy?('localhost').should be_true
        end
        it "should by true for 127.0.0.1" do
          env.no_proxy?('127.0.0.1').should be_true
        end
        it "should be false for some host" do
          env.no_proxy?('www.example.com').should be_false
        end
      end
      context "with a proxy exception list" do
        with_env "no_proxy" => "noproxy1.com, no.proxy.com"
        it "should not proxy to host in list" do
          env.no_proxy?("noproxy1.com").should be_true
        end
        it "should not proxy to subdomain from host in list" do
          env.no_proxy?("subdomain.noproxy1.com").should be_true
        end
        it "should proxy to host not in list" do
          env.no_proxy?("no.proxy.com.org").should be_false
        end
      end
    end

    describe "#net_http_class" do
      let(:proxied_host) { "www.example.com" }
      context "sanity" do
        with_env  "http_proxy" => nil

        it "should have the normal class" do
          env.net_http_class(proxied_host).should be Net::HTTP
        end

        it "should not be marked as a proxy class" do
          env.net_http_class(proxied_host).should_not be_proxy_class
        end
      end

      context "with a complex proxy" do
        with_env  "http_proxy" => "admin:secret@example.com"

        it "should not by marked as a proxy class for localhost" do
          env.net_http_class('localhost').should_not be_proxy_class
        end
        it "should not have the normal class" do
          env.net_http_class(proxied_host).should_not be Net::HTTP
        end

        it "should have a subclass the normal class" do
          env.net_http_class(proxied_host).should < Net::HTTP
        end

        it "should be marked as a proxy class" do
          env.net_http_class(proxied_host).should be_proxy_class
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

          actual_attributes.should == expected_attributes
        end

        context "with an excluded host" do
          with_env "no_proxy" => "no.proxy.com, noproxy.com"
          it "should have the normal class" do
            env.net_http_class("noproxy.com").should be Net::HTTP
          end
          it "should have the normal class for a subdomain" do
            env.net_http_class("www.noproxy.com").should be Net::HTTP
          end
        end
      end
      
    end

  end
end
