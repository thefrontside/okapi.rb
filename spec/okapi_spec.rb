require "spec_helper"

RSpec.describe Okapi do
  let(:url) { 'https://okapi.frontside.io' }
  let(:okapi) { Okapi::Client.new(url) }
  let(:modules) { okapi.modules }
  let(:first) { modules.first }

  it "has a list of modules" do
    expect(okapi.modules.length).to eql(11)
  end

end
