# Okapi
[![Gem Version](https://badge.fury.io/rb/okapi.svg)](https://badge.fury.io/rb/okapi)
[![Build Status](https://travis-ci.org/thefrontside/okapi.rb.svg?branch=master)](https://travis-ci.org/thefrontside/okapi.rb)

Ruby bindings and command line utility for the [Okapi][1] API gateway.

## Synopsis

To make calls to an Okapi gateway from Ruby, instantiate an instance
of the `Okapi::Client` class by passing in the URL, Tenant, and
auth_token to use for requests.

``` ruby
require 'okapi'
okapi = Okapi::Client.new('https://okapi.frontside.io', "fs", "<MY-AUTH-TOKEN>")
okapi.get("/_/proxy/modules") //=> [{id: 'mod-kb-ebsco'}, {id: 'mod-config'}]
```

The `okapi` client has methods corresponding to the major `REST`ful
verbs: `okap.get`, `okapi.post`, `okapi.put`, `okapi.delete`

By default, even if you provided them to the constructor, the client
does not send tenant and auth information with the request. This is
because the gateway will reject requests that provide this information
when it is not needed. For example, an authorization request that
provides an auth token will result in an error, so you don't want to
send it.

To send tenant, use the `tenant` property on the client
to access an `Okapi::Client` that _will_ send tenant information.

``` ruby
okapi.tentant.post('/authn/login', username: 'admin', password: 'password')
```

To send both tenant _and_ authorization information with a request,
use the `user` property of the okapi client which will give you a
client that _will_ send both these bits of information with the
request:

``` ruby
okapi.user.get('/eholdings/configuration')
```

## Command Line

The okapi gem comes with a command line utility to help you easily
interact with an Okapi gateway from your shell.

![installing, configuring and using the okapi command line
tool](okapi-command-line.gif "Okapi Command Line Demo")

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'okapi'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install okapi


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/rspec spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/thefrontside/okapi.rb

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

[1]: https://github.com/folio-org/okapi
