# frozen_string_literal: true

begin
  require "libhoney"
rescue LoadError
  raise LoadError, <<~MSG
    Could not load the libhoney gem. Use `gem install libhoney` to install it.
  MSG
end

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
