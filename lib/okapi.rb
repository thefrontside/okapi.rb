require "okapi/version"
require 'net/https'
require 'open-uri'
require 'json'

module Okapi
  class Client
    def initialize(url, tenant_id = nil, authtoken = nil)
      @url = url
      @tenant_id = tenant_id
    end

    def modules
      endpoint = "#{@url}/_/proxy/modules"
      open(endpoint) do |response|
        JSON.parse(response.read)
      end
    end

    def has_interface?(interface_name)
      get("/_/proxy/tenants/#{@tenant_id}/interfaces/#{interface_name}") do |json|
        json.length > 0
      end
    end


    def uri
      URI(@url)
    end

    def get(path)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
      end

      http.start do
        headers = {}
        headers['X-Okapi-Tenant'] = @tenant_id if @tenant_id
        headers['X-Okapi-Token'] = @authtoken if @authtoken
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

    def with_tenant(tenant_id)
      client = Okapi::Client.new(@url, tenant_id)
      if block_given?
        yield client
      else
        client
      end
    end

    def with_authtoken(token)
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
