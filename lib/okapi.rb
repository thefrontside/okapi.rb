require "okapi/version"
require 'net/https'
require 'open-uri'
require 'json'

module Okapi
  class Client
    def initialize(url)
      @url = url
    end

    def modules
      endpoint = "#{@url}/_/proxy/modules"
      p endpoint
      open(endpoint) do |response|
        JSON.parse(response.read)
      end
    end
  end
end
