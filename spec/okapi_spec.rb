require "spec_helper"
require "okapi/cli"


RSpec.describe Okapi do
  def okapi(command)
    VCR.use_cassette("okapi-cli-specs") do
      JSON.parse Okapi::CLI.new('/install/path/okapi').run command.split(/\s+/)
    end
  end

  let(:modules) { okapi "--url https://okapi.frontside.io modules:index" }

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

  # describe "setting configuration options" do
  #   # before do
  #   #   config_file = "#{Dir.tmpdir}/okapi-config"
  #   #   FileUtils.rm(config_file) if File.exists?(config_file)
  #   #   okapi "--config #{config_file} config:set OKAPI_URL=https://okapi.frontside.io OKAPI_TENANT=fs"
  #   # end
  #   pending "can read back the settings" do
  #     # expect{okapi "modules:index"}.not_to raise_error
  #   end
  # end
end
