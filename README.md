# Minitrace

Minitrace is a minimalist, vendor-agnostic distributed tracing framework. Instrument your code using structured events, then send those events to a configurable backend.

:warning: **DISCLAIMER** :warning:

**For any serious project, you probably want to use [OpenTelemetry](https://github.com/open-telemetry/opentelemetry-ruby) or a vendor-specific library like the [Honeycomb Beeline](https://github.com/honeycombio/beeline-ruby/).**

I'm just a guy with a particular aesthetic sense who's discontent with how bloated the status quo feels. So, in the same vein as [minitest versus rspec](https://ajvondrak.github.io/soapbox/2020/05/08/doing-magic-right/), minitrace is a lighter-weight alternative to OTel. Unlike minitrace, OTel actually has the backing of an entire standardization community and receives constant development. I don't want to [make more problems](https://xkcd.com/927).

Indeed, this project is largely an educational exercise. At least the initial implementation should roughly follow the path laid out in some [material I wrote](https://ajvondrak.github.io/soapbox/2021/02/25/the-path-from-logs-to-traces/) about tracing with structured events. I intend to use this repo to show people how tracing works under the hood with as little cruft as possible. Watch this space for links as they become available.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'minitrace'
```

And then execute:

```console
$ bundle install
```

Or install it yourself as:

```console
$ gem install minitrace
```

## Usage

TODO: Write usage instructions here

## Contributing

[Issues](https://github.com/ajvondrak/minitrace/issues) and [pull requests](https://github.com/ajvondrak/minitrace/pulls) are welcome. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/[USERNAME]/minitrace/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Minitrace project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/minitrace/blob/master/CODE_OF_CONDUCT.md).
