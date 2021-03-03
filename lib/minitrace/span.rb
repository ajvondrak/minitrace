# frozen_string_literal: true

class Minitrace::Span < Minitrace::Event
  def initialize
    super
    add_field("timestamp", Time.now)
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
end
