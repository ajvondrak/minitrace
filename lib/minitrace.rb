# frozen_string_literal: true

require "minitrace/version"
require "minitrace/backends"
require "minitrace/event"

# A minimalist tracing framework.
module Minitrace
  class << self
    attr_accessor :backend

    def events
      @events ||= []
    end

    def with_event
      events << Minitrace::Event.new
      yield
    ensure
      events.pop.fire
    end

    def add_field(field, value)
      events.last&.add_field(field, value)
    end

    def add_fields(fields)
      events.last&.add_fields(fields)
    end
  end
end
