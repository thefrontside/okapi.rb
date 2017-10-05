module Okapi
  class Settings
    def initialize(url, tenant, token)
      @url = url
      @tenant = tenant
      @token = token
    end
    def url
      ENV['OKAPI_URL'] || @url or raise ConfigurationError, <<-EOM
this operation requires the url of your Okapi gateway, but it couldn't be found.

You can fix this by setting either the `OKAPI_URL` environment variable, or
using the `--url` option if you're using the command line.
--
EOM
      URI(ENV['OKAPI_URL'] || @url)
    end

    def tenant
      ENV['OKAPI_TENANT'] || @tenant or raise ConfigurationError, <<-EOM
this operation requires a tenant id, but it couldn't be found.

You can fix this by setting either the `OKAPI_TENANT` environment variable, or
using the `--tenant` option if you're using the command line.
EOM
    end

    def token
      ENV['OKAPI_TOKEN'] || @token or raise ConfigurationError, <<-EOM
this operation requires you to be logged in, and already authenticated with
your Okapi cluster.

You can fix this by obtaining an authenication token, and then using it by
either setting the `OKAPI_TOKEN` environment variable or using the
`--token` option from the command line.
EOM
    end
  end

end
