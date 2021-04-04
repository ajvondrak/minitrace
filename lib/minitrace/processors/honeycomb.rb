# frozen_string_literal: true

Minitrace::Integrations.require("libhoney")

class Minitrace::Processors::Honeycomb
  attr_reader :client

  def initialize(client: nil, **options)
    @client = client || Libhoney::Client.new(**options)
    at_exit { @client.close }
  end

  def process(events)
    rate = events.last.fields["sample_rate"] || 1
    events.each do |event|
      fields = event.fields.dup
      hny = @client.event
      hny.timestamp = fields.delete("timestamp") || Time.now
      hny.sample_rate = fields.delete("sample_rate") || rate
      hny.add(fields)
      hny.send_presampled
    end
  end
end
