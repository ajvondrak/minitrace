# frozen_string_literal: true

require "securerandom"

class Minitrace::Span < Minitrace::Event
  def initialize
    super
    add_field("timestamp", Time.now)
    add_field("trace.trace_id", trace_id)
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

  def trace_id
    Minitrace.events.last&.fields&.dig("trace.trace_id") || SecureRandom.hex(16)
  end
end
