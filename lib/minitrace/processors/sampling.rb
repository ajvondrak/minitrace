# frozen_string_literal: true

require "digest"

class Minitrace::Processors::Sampling
  def process(events)
    case Minitrace.backend.mode
    when :head
      process_head(events)
    when :tail
      process_tail(events)
    end
  end

  private

  MAXINT = 2**32 - 1

  def process_head(events)
    event = events.last
    rate = event.fields["sample_rate"] || 1
    return if rate == 1
    throw :drop if rate == 0
    digest = Digest::SHA1.digest(event.fields["trace.trace_id"])
    uint32 = digest.unpack1("I>") # first 4 bytes, big endian
    throw :drop if uint32 > MAXINT / rate
  end

  def process_tail(events)
    root = events.last
    rate = root.fields["sample_rate"] || 1
    return if rate == 1
    throw :drop if rate == 0
    throw :drop unless rand(rate) == 0
  end
end
