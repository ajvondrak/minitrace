# frozen_string_literal: true

require "minitrace/version"
require "minitrace/integrations"
require "minitrace/backends"
require "minitrace/event"
require "minitrace/span"
require "minitrace/sync_error"

# A minimalist tracing framework.
module Minitrace
  class << self
    attr_accessor :backend

    def events
      Thread.current["Minitrace.events"] ||= []
    end

    def event
      Minitrace::Event.new
    end

    def with_event(event = Minitrace::Event.new)
      events << event
      yield
    rescue => e
      event.on_error(e)
    ensure
      pending = events.pop
      raise Minitrace::SyncError.new(event, pending) unless event == pending
      pending.fire
    end

    def span(name)
      Minitrace::Span.new.add_field("name", name)
    end

    def with_span(name, &block)
      with_event(span(name), &block)
    end

    def add_field(field, value)
      events.last&.add_field(field, value)
    end

    def add_fields(fields)
      events.last&.add_fields(fields)
    end
  end
end
