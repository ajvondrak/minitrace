# frozen_string_literal: true

require "test_helper"

class Minitrace::Processors::HookTest < Minitest::Test
  def test_in_isolation
    hook = Minitrace::Processors::Hook.new do |event|
      event.add_field("+", "added")
      event.fields.delete("-")
      event.fields["!"] += "d" if event.fields.include?("!")
    end

    a = Minitrace::Event.new.add_fields("name" => "a")
    b = Minitrace::Event.new.add_fields("name" => "b", "-" => "removed")
    c = Minitrace::Event.new.add_fields("name" => "c", "!" => "change")

    hook.process([a, b, c])

    assert { a.fields == { "name" => "a", "+" => "added" } }
    assert { b.fields == { "name" => "b", "+" => "added" } }
    assert { c.fields == { "name" => "c", "+" => "added", "!" => "changed" } }
  end

  def test_in_backend
    Minitrace.backend = Minitrace::Backend.new do
      use Minitrace::Processors::Hook do |event|
        event.fields["x"] ||= 1
      end
      use Minitrace::Processors::Hook do |event|
        event.fields["x"] += 1
      end
      use Minitrace::Processors::Spy
    end

    a = Minitrace::Event.new.add_fields("name" => "a")
    b = Minitrace::Event.new.add_fields("name" => "b", "x" => 2)
    c = Minitrace::Event.new.add_fields("name" => "c", "x" => 3)

    Minitrace.backend.process(a)
    Minitrace.backend.process(b)
    Minitrace.backend.process(c)

    assert { processed.size == 3 }
    assert { processed[0].fields == { "name" => "a", "x" => 2 } }
    assert { processed[1].fields == { "name" => "b", "x" => 3 } }
    assert { processed[2].fields == { "name" => "c", "x" => 4 } }
  end
end
