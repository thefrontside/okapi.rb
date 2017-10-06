require "okapi"
require "okapi/cli/config"
require "clamp"


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

    subcommand "configurations:index", "get a list of configuration entries for this client" do
      def model
        client.user.get('/configurations/entries')
      end
    end

    subcommand "login", "authenticate to okapi and store credentials" do
      def model
        client.tenant.post("/authn/login", {})
      end
    end

    subcommand "logout", "destroy existing credentials" do
      def execute
        puts "logout"
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
  end
end
