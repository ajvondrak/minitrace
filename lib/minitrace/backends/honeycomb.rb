# frozen_string_literal: true

Minitrace::Integrations.require("libhoney")

class Minitrace::Backends::Honeycomb < Minitrace::Backend
  attr_reader :client

  def initialize(client: nil, **options)
    super()
    @client = client || Libhoney::Client.new(**options)
  end

  def process(event)
    fields = event.fields.dup
    hny = @client.event
    hny.timestamp = fields.delete("timestamp") || Time.now
    hny.add(fields)
    hny.send
  end
end
