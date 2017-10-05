require "okapi"
require "clamp"

module Okapi
  class CLI < Clamp::Command
    option "--config", "CONFIG_FILE", "use persistent configuration from this file"
    option "--url", "URL",  "use okapi cluster at URL"
    option "--tenant", "TENANT",  "connect using this tenant"
    option "--token", "TOKEN", "authenticate requests with TOKEN"

    subcommand "config:set", "set the CLI configuration variable {OKAPI_URL, OKAPI_TENANT, OKAPI_TOKEN}" do
      def model

      end
    end

    subcommand "configurations:index", "get a list of configuration entries for this client" do
      def model
        client.user.configuration.entries.index
      end
    end

    subcommand "login", "authenticate to okapi and store credentials" do
      def model
        client.tenant.login.login.create
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
      JSON.pretty_generate model
    end

    def settings
      Settings.new(url, tenant, token)
    end
  end
end
