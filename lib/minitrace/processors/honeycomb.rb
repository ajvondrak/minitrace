# frozen_string_literal: true

Minitrace::Integrations.require("libhoney")

class Minitrace::Processors::Honeycomb
  attr_reader :client

  def initialize(client: nil, **options)
    @client = client || Libhoney::Client.new(**options)
  end

  def process(event)
    fields = event.fields.dup
    hny = @client.event
    hny.timestamp = fields.delete("timestamp") || Time.now
    hny.sample_rate = fields.delete("sample_rate") || 1
    hny.add(fields)
    hny.send_presampled
  end
end
