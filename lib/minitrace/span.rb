# frozen_string_literal: true

require "securerandom"

class Minitrace::Span < Minitrace::Event
  def initialize
    super
    add_field("timestamp", Time.now)
    add_fields(trace)
    @start = monotonic_time_ms
  end

  def fire
    return if fired?
    add_field("duration_ms", monotonic_time_ms - @start)
    super
  end

  private

  def monotonic_time_ms
    Process.clock_gettime(Process::CLOCK_MONOTONIC, :float_millisecond)
  end

  def parent(field)
    Minitrace.events.last&.fields&.dig(field)
  end

  def trace
    {
      "trace.trace_id" => parent("trace.trace_id") || SecureRandom.hex(16),
      "trace.parent_id" => parent("trace.span_id"),
      "trace.span_id" => SecureRandom.hex(8),
    }.compact
  end
end
