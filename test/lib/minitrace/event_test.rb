# frozen_string_literal: true

require "test_helper"

class Minitrace::EventTest < Minitest::Test
  def test_add_field
    event = Minitrace::Event.new
    assert { event.fields == {} }

    assert { event.add_field("a", 1) == event }
    assert { event.fields == { "a" => 1 } }

    assert { event.add_field("b", 2) == event }
    assert { event.fields == { "a" => 1, "b" => 2 } }

    assert { event.add_field("a", 3) == event }
    assert { event.fields == { "a" => 3, "b" => 2 } }
  end

  def test_add_fields
    event = Minitrace::Event.new
    assert { event.fields == {} }
    assert { event.add_fields("a" => 1, "b" => 2) == event }
    assert { event.fields == { "a" => 1, "b" => 2 } }
    assert { event.add_fields("b" => 3, "c" => 5) == event }
    assert { event.fields == { "a" => 1, "b" => 3, "c" => 5 } }
  end

  def test_fire
    event = Minitrace::Event.new
    assert { processed.empty? }
    event.fire
    assert { processed == [event] }
  end

  def test_double_fire
    event = Minitrace::Event.new
    assert { processed.empty? }
    event.fire
    assert { processed == [event] }
    event.fire
    assert { processed == [event] }
  end

  def test_on_error
    error = Class.new(StandardError)
    event = Minitrace::Event.new
    assert_raises(error) { event.on_error(error.new("zoinks")) }
    assert { event.fields["error"] == error.name }
    assert { event.fields["error_detail"] == "zoinks" }
  end
end
