# frozen_string_literal: true

require "test_helper"
require "libhoney"

class Minitrace::Backends::HoneycombTest < Minitest::Test
  def test_client
    client = Libhoney::TestClient.new
    backend = Minitrace::Backends::Honeycomb.new(client: client)
    assert { backend.client == client }
  end

  def test_options
    backend = Minitrace::Backends::Honeycomb.new(writekey: "wk", dataset: "ds")
    assert { backend.client.is_a?(Libhoney::Client) }
    assert { backend.client.writekey == "wk" }
    assert { backend.client.dataset == "ds" }
  end

  def backend
    @backend ||= Minitrace::Backends::Honeycomb.new(
      client: Libhoney::TestClient.new,
    )
  end

  def test_process
    event = Minitrace::Event.new
    event.add_field("lib", "hny")

    Time.stub(:now, Time.at(123)) do
      backend.process(event)
    end

    assert { backend.client.events.size == 1 }
    assert { backend.client.events.last.timestamp == Time.at(123) }
    assert { backend.client.events.last.data == { "lib" => "hny" } }
    assert { event.fields == { "lib" => "hny" } }
  end

  def test_process_with_timestamp
    event = Minitrace::Event.new
    event.add_field("timestamp", Time.at(456))
    event.add_field("lib", "hny")

    Time.stub(:now, Time.at(123)) do
      backend.process(event)
    end

    assert { backend.client.events.size == 1 }
    assert { backend.client.events.last.timestamp == Time.at(456) }
    assert { backend.client.events.last.data == { "lib" => "hny" } }
    assert { event.fields == { "timestamp" => Time.at(456), "lib" => "hny" } }
  end
end
