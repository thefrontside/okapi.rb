require "okapi"
require "okapi/cli/config"
require "clamp"
require "highline"

module Okapi
  class CLI < Clamp::Command
    option "--config", "CONFIG_FILE", "use persistent configuration from this file", default: ImplicitConfig.new do |config|
      ExplicitConfig.new(config)
    end
    option "--url", "URL",  "use okapi cluster at URL"
    option "--tenant", "TENANT",  "connect using this tenant"
    option "--token", "TOKEN", "authenticate requests with TOKEN"

    subcommand "config", "show all configured variables" do
      def model
        variables.read!
      end
    end

    subcommand "config:set", "set the CLI configuration variable {OKAPI_URL, OKAPI_TENANT, OKAPI_TOKEN}" do
      parameter "ENV_VARS ...", "persist all ENV_VAR values for future use"

      def model
        variables.read! force: true
        variables.merge env_vars_list
        variables.write!
        "configuration written to #{variables.filename}"
      end
    end

    subcommand "config:delete", "delete configuration variables" do
      parameter "VARS ...", "delete configuration variables"

      def model
        variables.read! force: true
        deletions = variables.delete_all! vars_list
        variables.write!
        "deleted #{deletions} variables from #{variables.filename}"
      end
    end

    subcommand "login", "authenticate to okapi and store credentials" do
      def model
        username = console.ask("username: ")
        password = console.ask("password: ") { |q| q.echo = "*" }
        client.tenant.post("/authn/login", username: username, password: password) do |json, response|
          token = response['x-okapi-token']
          variables.read! force: true
          variables.merge ["OKAPI_TOKEN=#{token}"]
          variables.write!
          "Login successful. Token saved to #{variables.filename}"
        end
      end
    end

    subcommand "logout", "destroy existing credentials" do
      def execute
        variables.read!
        deletions = variables.delete_all! ["OKAPI_TOKEN"]
        if deletions > 0
          variables.write!
          "Logged out. Updated #{variables.filename}"
        else
          "Configuration at #{variables.filename} is not currently logged in. Doing nothing."
        end
      end
    end

    subcommand "get", "issue a GET request" do
      parameter "PATH", "PATH to fetch from the api"

      def model
        client.get path
      end
    end

    subcommand "tenant:get", "issue a GET request as a Tenant" do
      parameter "PATH", "PATH to fetch from the api"

      def model
        client.tenant.get path
      end
    end

    subcommand "user:get", "issue a GET request as a User" do
      parameter "PATH", "PATH to fetch from the api"

      def model
        client.user.get path
      end
    end

    subcommand "modules:index", "show a listing of all installed modules" do
      def model
        client.modules
      end
    end

    def client
      Okapi::Client.new(settings)
    end

    def execute
      result = model
      if result.is_a?(String)
        result
      else
        JSON.pretty_generate result
      end
    end

    def settings
      variables.load!
      Settings.new(url, tenant, token)
    end

    def variables
      @variables ||= PersistentVariables.new(config)
    end

    def console
      HighLine.new
    end

    def self.run(*args, &block)
      super(*args, &block)
    rescue Okapi::ConfigurationError => e
      e.message
    rescue Okapi::RequestError => e
      e.message
    end
  end
end
