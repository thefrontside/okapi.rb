require "okapi/version"
require 'net/https'
require 'open-uri'
require 'json'

module Okapi

  class Client
    def initialize(url, tenant_id = nil, authtoken = nil)
      @url = url
      @tenant_id = tenant_id
      @authtoken = authtoken
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

    def post(path, body)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
      end

      http.start do
        headers = {'Content-Type' => 'application/json', 'Accept' => 'application/json'}
        headers['X-Okapi-Tenant'] = @tenant_id if @tenant_id
        headers['X-Okapi-Token'] = @authtoken if @authtoken
        response = http.post(path, JSON.generate(body), headers)

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
      client = self.class.new(@url, @tenant_id, token)
      if block_given?
        yield client
      else
        client
      end
    end

    def login(options = {})
      username = options[:username] || ''
      password = options[:password] || ''
      [username, password]
    end


    def login
      @@login_module ||= define_okapi_module('login', 'authn', login: [ :create ], credentials: [ :index, :show, :create, :update ] )
      @@login_module.new(self)
    end

    def configuration
      @@configuration_module ||= define_okapi_module('configuration', 'configuration', entries: [ :index ])
      @@configuration_module.new(self)
    end

    def define_okapi_module(interface_name, base_path, endpoints = {})

      verb_methods = {
        create: proc do |client, path, body|
          client.post path, body
        end,
        index: proc do | client, path |
          @client.get(path)
        end,
        update: proc do | client, path, id, body |
          "update!"
        end,
        show: proc do | client, path, id |
          @client.get("#{path}/#{id}")
        end
      }

      Class.new.tap do |module_class|

        module_class.class_eval do
          def initialize(client)
            @client = client
          end
        end

        endpoints.each do |entry|
          endpoint, verbs = entry

          endpoint_class = Class.new
          endpoint_class.class_eval do
            def initialize(client)
              @client = client
            end
          end
          verbs.each do |verb|
            method = verb_methods[verb]
            fail "`#{verb}` is not a valid action" unless method
            endpoint_class.send(:define_method, verb) do |*args|
              method.call(@client, "/#{base_path}/#{endpoint}", *args)
            end
          end

          module_class.send(:define_method, endpoint) { endpoint_class.new(@client) }
        end
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
