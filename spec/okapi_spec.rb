require "spec_helper"
require "okapi/cli"

RSpec.describe Okapi do
  def okapi(command)
    VCR.use_cassette("okapi-cli-specs") do
      Okapi::CLI.new('/install/path/okapi').run command.split(/\s+/)
    end
  end

  let(:modules) { JSON.parse okapi "--url https://okapi.frontside.io modules:index" }

  it "can get a list of modules" do
    expect(modules.length).to be(8)
    expect(modules.first["id"]).to eq("okapi-2.0.0")
  end

  it "blows up when trying to access an endpoint as a tenant, but no tenant id is specified" do
    expect{ okapi "--url https://okapi.frontside.io tenant:get /authn/credentials"}.to raise_error(Okapi::ConfigurationError)
  end

  it "blows up when trying to access an endpoint as a user, but no auth token is specified" do
    expect{ okapi "--url https://okapi.frontside.io --tenant fs user:get /configurations/entries"}.to raise_error(Okapi::ConfigurationError)
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
      okapi "--config #{@config_file} config:set OKAPI_URL=https://okapi.frontside.io"
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
      okapi "config:set OKAPI_URL=https://okapi.frontside.io OKAPI_TENANT=fs"
      simulate_stdin_with("username", "password") { okapi "login" }
    end

    it "saves the token to the configuration file" do
      expect(config).to include("OKAPI_TOKEN")
    end

    it "uses the saved token to access an endpoint as a user" do
      expect{okapi "user:get /configurations/entries"}.to_not raise_error
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
