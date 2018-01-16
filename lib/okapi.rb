require "okapi/version"
require "okapi/settings"
require 'net/https'
require 'open-uri'
require 'json'

module Okapi
  class ConfigurationError < StandardError; end

  class Client
    def initialize(url = nil, tenant = nil, token = nil)
      @url, @tenant, @token = url, tenant, token
    end

    def settings
      Settings.new(@url, @tenant, @token)
    end

    def url
      settings.url
    end

    def get(path)
      request(:get, path) do |response|
        json = JSON.parse(response.body)
        if block_given?
          yield json, response
        else
          json
        end
      end
    end

    def post(path, body)
      request(:post, path, JSON.generate(body)) do |response|
        json = JSON.parse(response.body)
        if block_given?
          yield json, response
        else
          json
        end
      end
    end

    def delete(path)
      request(:delete, path, nil, 'Accept' => 'text/plain')
    end

    def request(verb, path, body = nil, header_overrides = {})
      http = Net::HTTP.new(url.host, url.port)
      if url.scheme == "https"
        http.use_ssl = true
      end
      http.start do
        args = [body].compact
        response = http.send(verb, path, *args, headers.merge(header_overrides))
        RequestError.maybe_fail! response
        if block_given?
          yield response
        else
          response
        end
      end
    end

    def headers
      {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
    end

    def tenant
      Tenant.new(@url, @tenant, @token)
    end

    def user
      User.new(@url, @tenant, @token)
    end

    class Tenant < self
      def headers
        super.merge "X-Okapi-Tenant" => settings.tenant
      end
    end

    class User < Tenant
      def headers
        super.merge "X-Okapi-Token" => settings.token
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
