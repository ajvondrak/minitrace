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
      honey.process([event])
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
      honey.process([event])
    end

    assert { honey.client.events.size == 1 }
    assert { honey.client.events.last.timestamp == Time.at(456) }
    assert { honey.client.events.last.data == { "lib" => "hny" } }
    assert { event.fields == { "timestamp" => Time.at(456), "lib" => "hny" } }
  end

  def test_process_with_sample_rate
    event = Minitrace::Event.new
    event.add_field("sample_rate", 8_675_309)
    event.add_field("lib", "hny")

    honey.process([event])

    assert { honey.client.events.size == 1 }
    assert { honey.client.events.last.sample_rate == 8_675_309 }
    assert { honey.client.events.last.data == { "lib" => "hny" } }
  end

  def test_trace
    root = Minitrace::Event.new.add_fields(
      "name" => "root",
      "timestamp" => Time.at(123),
      "sample_rate" => 123,
    )
    leaf = Minitrace::Event.new.add_fields(
      "name" => "leaf",
      "timestamp" => Time.at(456),
    )
    special = Minitrace::Event.new.add_fields(
      "name" => "special",
      "sample_rate" => 789,
    )

    Time.stub(:now, Time.at(789)) do
      honey.process([special, leaf, root])
    end

    assert { honey.client.events.size == 3 }

    assert { honey.client.events[0].data == { "name" => "special" } }
    assert { honey.client.events[0].timestamp == Time.at(789) }
    assert { honey.client.events[0].sample_rate == 789 }

    assert { honey.client.events[1].data == { "name" => "leaf" } }
    assert { honey.client.events[1].timestamp == Time.at(456) }
    assert { honey.client.events[1].sample_rate == 123 }

    assert { honey.client.events[2].data == { "name" => "root" } }
    assert { honey.client.events[2].timestamp == Time.at(123) }
    assert { honey.client.events[2].sample_rate == 123 }
  end
end
