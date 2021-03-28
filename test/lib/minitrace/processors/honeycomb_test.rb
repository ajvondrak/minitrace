# frozen_string_literal: true

require "test_helper"
require "libhoney"

class Minitrace::Processors::HoneycombTest < Minitest::Test
  def test_client
    client = Libhoney::TestClient.new
    honey = Minitrace::Processors::Honeycomb.new(client: client)
    assert { honey.client == client }
  end

  def test_options
    honey = Minitrace::Processors::Honeycomb.new(writekey: "wk", dataset: "ds")
    assert { honey.client.is_a?(Libhoney::Client) }
    assert { honey.client.writekey == "wk" }
    assert { honey.client.dataset == "ds" }
  end

  def honey
    @honey ||= Minitrace::Processors::Honeycomb.new(
      client: Libhoney::TestClient.new,
    )
  end

  def test_process
    event = Minitrace::Event.new
    event.add_field("lib", "hny")

    Time.stub(:now, Time.at(123)) do
      honey.process(event)
    end

    assert { honey.client.events.size == 1 }
    assert { honey.client.events.last.timestamp == Time.at(123) }
    assert { honey.client.events.last.data == { "lib" => "hny" } }
    assert { event.fields == { "lib" => "hny" } }
  end

  def test_process_with_timestamp
    event = Minitrace::Event.new
    event.add_field("timestamp", Time.at(456))
    event.add_field("lib", "hny")

    Time.stub(:now, Time.at(123)) do
      honey.process(event)
    end

    assert { honey.client.events.size == 1 }
    assert { honey.client.events.last.timestamp == Time.at(456) }
    assert { honey.client.events.last.data == { "lib" => "hny" } }
    assert { event.fields == { "timestamp" => Time.at(456), "lib" => "hny" } }
  end
end
