require "spec_helper"

RSpec.describe Okapi do
  let(:url) { 'https://okapi.frontside.io' }
  let(:okapi) { Okapi::Client.new(url) }
  let(:modules) { okapi.modules }
  let(:first) { modules.first }

  it "has a list of modules" do
    expect(okapi.modules.length).to eql(11)
  end

  describe "a specific tenant" do
    let(:tenant) { okapi.with_tenant 'fs' }

    it "can query whether an interface exists" do
      expect(tenant.has_interface?("configuration")).to be true
      expect(tenant.has_interface?("blip-bloop")).to be false
    end


    describe "a specific user" do
      let(:token) { tenant.login.login.create(username: 'devolio', password: 'testpass') }
      let(:user) { tenant.with_authtoken token }

      pending "list existing configuration entries" do
        expect(user.configuration.entries.get)
      end

      it "can add a new configuration entry"

      it "can update an existing configuration entry"

      it "can delete an existing configuration entry"
      describe "when the configuration interface doesn't exist" do
        it "blows up in a helpful way"
      end

      describe "when the tenant doesnt exist" do
        it "blows up in a helpful way"
      end
    end
  end
end

# tenant = client.tenant('fs')
# config = tenant.interfaces['configuration']
