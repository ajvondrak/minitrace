# frozen_string_literal: true

require "minitrace/backend"

module Minitrace::Backends
  autoload :Spy, "minitrace/backends/spy"
  autoload :Honeycomb, "minitrace/backends/honeycomb"
end
