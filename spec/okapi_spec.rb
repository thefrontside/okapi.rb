require "spec_helper"
require "okapi/cli"

RSpec.describe Okapi do
  def okapi(command)
    VCR.use_cassette("okapi-cli-specs") do
      Okapi::CLI.new('/install/path/okapi').run command.split(/\s+/)
    end
  end

  let(:modules) { JSON.parse okapi "--url https://okapi-sandbox.frontside.io modules:index" }

  it "can get a list of modules" do
    expect(modules.length).to be(440)
    expect(modules.first["id"]).to eq("permissions-module-4.0.4")
  end

  it "blows up when trying to access an endpoint with no user, and no tenant id is specified" do
    expect{ okapi "--url https://okapi.frontside.io show --no-user /authn/credentials"}.to raise_error(Okapi::ConfigurationError)
  end

  it "blows up when trying to access an endpoint that needs a user, but no auth token is specified" do
    expect{ okapi "--url https://okapi.frontside.io --tenant fs show /configurations/entries"}.to raise_error(Okapi::ConfigurationError)
  end

  it "blows up if you try to specify a configuration file that doesn't exist" do
    expect{ okapi "--config does/not/exist modules:index" }
  end

  describe "setting configuration options" do
    before do
      okapi "config:set OKAPI_URL=https://okapi.frontside.io"
    end

    it "can read back the settings" do
      expect{okapi "modules:index"}.not_to raise_error
    end

    describe "deleting a configuration option" do
      before do
        okapi "config:delete OKAPI_URL"
      end

      it "removes the persistent setting" do
        expect{okapi "modules:index"}.to raise_error(Okapi::ConfigurationError)
      end
    end
  end

  describe "setting configuration options with a specified config file" do
    before do
      @config_file = "spec/sandbox/okapi-config"
      FileUtils.rm_rf(@config_file)
      okapi "--config #{@config_file} config:set OKAPI_URL=https://okapi-sandbox.frontside.io"
    end

    it "can read back the settings" do
      expect{okapi "--config #{@config_file} modules:index"}.not_to raise_error
    end

    it "does not overwrite the default settings" do
      expect{okapi "modules:index"}.to raise_error(Okapi::ConfigurationError)
    end
  end

  describe "logging in" do
    def simulate_stdin_with(*args)
      $stdout = StringIO.new
      $stdin = StringIO.new
      $stdin.puts(args.shift) until args.empty?
      $stdin.rewind
      yield
    ensure
      $stdout = STDOUT
      $stdin = STDIN
    end

    let(:config) { JSON.parse okapi "config" }

    before do
      okapi "config:set OKAPI_URL=https://okapi-sandbox.frontside.io OKAPI_TENANT=fs"
      simulate_stdin_with("admin", "admin") { okapi "login" }
    end

    it "saves the token to the configuration file" do
      expect(config).to include("OKAPI_TOKEN")
    end

    it "uses the saved token to access an endpoint as a user" do
      expect{okapi "show /configurations/entries"}.to_not raise_error
    end

    describe "creating a resource" do
      before do

        simulate_stdin_with(<<-EOJSON) do
{
  "module": "KB_EBSCO",
  "configName": "api_credentials",
  "code": "kb.ebsco.credentials",
  "description": "EBSCO RM-API Credentials",
  "enabled": true,
  "value": "customer-id=xxx.xxx&api-key=xxx.xxxx"
}
EOJSON
          @result = JSON.parse okapi "create /configurations/entries"
        end
        @entry =  JSON.parse okapi "show /configurations/entries/#{@result["id"]}"
      end

      it "stores the JSON" do
        expect(@entry["id"]).to eql(@result["id"])
        expect(@entry["code"]).to eql("kb.ebsco.credentials")
      end

      describe "and then deleting it" do
        before do
          okapi "destroy /configurations/entries/#{@result["id"]}"
        end
        it "no longer can be found as a resource" do
          expect{okapi "show /configurations/#{@result["id"]}"}.to raise_error(Okapi::RequestError, /HTTPNotFound/)
        end
      end

    end

    describe "and logging out" do
      before do
        okapi "logout"
      end

      it "deletes the token from the configuration file" do
        expect(config).to_not include("OKAPI_TOKEN")
      end
    end
  end
end
