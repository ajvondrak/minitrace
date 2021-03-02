# frozen_string_literal: true

require "minitrace/version"
require "minitrace/backends"
require "minitrace/event"

# A minimalist tracing framework.
module Minitrace
  class << self
    attr_accessor :backend
  end
end
