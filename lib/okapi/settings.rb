module Okapi
  class Settings
    def initialize(url, tenant, token)
      @url = url
      @tenant = tenant
      @token = token
    end
    def url
      get_var!(:url, <<~EOM) do |url|
this operation requires the url of your Okapi gateway, but it couldn't be found.

You can fix this by setting either the `OKAPI_URL` environment variable, or
using the `--url` option if you're using the command line.
EOM
        URI(url)
      end
    end

    def tenant
      get_var!(:tenant, <<~EOM)
this operation requires a tenant id, but it couldn't be found.

You can fix this by setting either the `OKAPI_TENANT` environment variable, or
using the `--tenant` option if you're using the command line.
EOM
    end

    def token
      get_var!(:token, <<~EOM)
this operation requires you to be logged in, and already authenticated with
your Okapi cluster.

You can fix this by obtaining an authenication token, and then using it by
either setting the `OKAPI_TOKEN` environment variable or using the
`--token` option from the command line.
EOM
    end

    def get_var!(symbol, error_msg)
      env_var_name = "OKAPI_#{symbol.to_s.upcase}"
      env_value = ENV[env_var_name]
      instance_value = instance_variable_get("@#{symbol}")
      if !env_value.nil? && !env_value.trim.empty?
        block_given? ? yield(env_value) : env_value
      elsif instance_value
        block_given? ? yield(instance_value) : instance_value
      else
        raise ConfigurationError, error_msg
      end
    end
  end

end
