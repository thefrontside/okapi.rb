module Okapi
  class Settings
    def initialize(url, tenant, token)
      @url = url
      @tenant = tenant
      @token = token
    end
    def url
      get_var!(:url, <<~EOM) do |url|
This operation requires the url of your Okapi gateway, but it couldn't be found.

You can fix this by setting either the `OKAPI_URL` environment variable, or
using the `--url` option if you're using the command line.

To store a default url, run `okapi config:set OKAPI_URL=<URL>`
EOM
        URI(url)
      end
    end

    def tenant
      get_var!(:tenant, <<~EOM)
This operation requires a tenant id, but it couldn't be found.

You can fix this by setting either the `OKAPI_TENANT` environment variable, or
using the `--tenant` option if you're using the command line.

To store a default tenant, run `okapi config:set OKAPI_TENANT=<TENANT>`
EOM
    end

    def token
      get_var!(:token, <<~EOM)
This operation requires you to be logged in, and already authenticated with
your Okapi cluster.

You can fix this by obtaining an authenication token, and then using it by
either setting the `OKAPI_TOKEN` environment variable or using the
`--token` option from the command line.

To log in with a username and password, run the command `okapi login`.
EOM
    end

    def get_var!(symbol, error_msg)
      env_var_name = "OKAPI_#{symbol.to_s.upcase}"
      env_value = ENV[env_var_name]
      instance_value = instance_variable_get("@#{symbol}")
      if instance_value && !instance_value.strip.empty?
        block_given? ? yield(instance_value) : instance_value
      elsif !env_value.nil? && !env_value.strip.empty?
        block_given? ? yield(env_value) : env_value
      else
        raise ConfigurationError, error_msg
      end
    end
  end

end
