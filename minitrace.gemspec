# frozen_string_literal: true

require_relative "lib/minitrace/version"

Gem::Specification.new do |spec|
  spec.name = "minitrace"
  spec.version = Minitrace::VERSION
  spec.required_ruby_version = ">= 2.6.0"
  spec.homepage = "https://github.com/ajvondrak/minitrace"
  spec.summary = "A minimalist tracing framework"
  spec.description = <<~DESC
    Minitrace is a minimalist, vendor-agnostic distributed tracing framework.
    Instrument your code using structured events, then send those events to a
    configurable backend.
  DESC
  spec.author = "Alex Vondrak"
  spec.email = "ajvondrak@gmail.com"
  spec.files = Dir["lib/**/*.rb"]
  spec.license = "MIT"
end
