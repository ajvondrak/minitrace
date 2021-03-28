# frozen_string_literal: true

require "digest"

class Minitrace::Processors::Sampling
  MAXINT = 2**32 - 1

  def process(events)
    event = events.last
    rate = event.fields["sample_rate"] || 1
    return if rate == 1
    throw :drop if rate == 0
    throw :drop if sha(event) > MAXINT / rate
  end

  private

  def sha(event)
    bytes = Digest::SHA1.digest(event.fields["trace.trace_id"])
    bytes.unpack1("I>") # unsigned 32-bit integer (= first 4 bytes), big endian
  end
end
