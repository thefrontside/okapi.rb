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
    expect(modules.length).to be(11)
    expect(modules.first["id"]).to eq("folio-mod-configuration")
  end

  it "blows up when accessing an endpoint that requires a tenant and none is specified" do
    expect{ okapi "--url https://okapi.frontside.io login"}.to raise_error(Okapi::ConfigurationError)
  end
  it "blows up when trying to access an endpoint that requires an auth token, but none is specified" do
    expect{ okapi "--url https://okapi.frontside.io --tenant fs configurations:index"}.to raise_error(Okapi::ConfigurationError)
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


end
