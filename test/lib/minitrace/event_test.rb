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
end
