require "okapi/version"
require "okapi/settings"
require 'net/https'
require 'open-uri'
require 'json'

module Okapi
  class ConfigurationError < StandardError; end

  class Client
    def initialize(settings)
      @settings = settings
    end

    def modules
      endpoint = "#{@settings.url}/_/proxy/modules"
      open(endpoint) do |response|
        JSON.parse(response.read)
      end
    end

    def has_interface?(interface_name)
      get("/_/proxy/tenants/#{@settings.tenant}/interfaces/#{interface_name}") do |json|
        json.length > 0
      end
    end

    def url
      @settings.url
    end

    def get(path)
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
      end

      http.start do
        response = http.get(path, headers)
        RequestError.maybe_fail! response
        json = JSON.parse(response.body)
        if block_given?
          yield json
        else
          json
        end
      end
    end

    def post(path, body)
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
      end

      http.start do
        response = http.post(path, JSON.generate(body), headers)

        RequestError.maybe_fail! response
        json = JSON.parse(response.body)
        if block_given?
          yield json, response
        else
          json
        end
      end
    end

    def headers
      {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    end

    def tenant
      Tenant.new(@settings)
    end

    def user
      User.new(@settings)
    end

    class Tenant < self
      def headers
        super.merge "X-Okapi-Tenant" => @settings.tenant
      end
    end

    class User < Tenant
      def headers
        super.merge "X-Okapi-Token" => @settings.token
      end
    end

  end

  class RequestError < StandardError
    attr_reader :response

    def initialize(response)
      super("#{response.class.to_s}: #{response.body}")
    end

    def self.maybe_fail!(response)
      fail new(response) unless response.code.to_i >= 200 && response.code.to_i < 300
    end
  end

end

# okapi configuration:get
