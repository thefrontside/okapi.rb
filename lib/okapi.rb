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
          yield json
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
          client.get(path)
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
