# frozen_string_literal: true

require "test_helper"

class Minitrace::BackendTest < Minitest::Test
  def basic
    @basic ||= Minitrace::Backend.new do
      use Minitrace::Processors::Spy
      use Minitrace::Processors::Spy
      use Minitrace::Processors::Spy
    end
  end

  def test_basic
    event = Minitrace::Event.new
    basic.process(event)
    basic.processors.each do |spy|
      assert { spy.processed == [event] }
    end
  end

  def drop
    return @drop if defined?(@drop)

    processor = Class.new do
      def process(events)
        throw :drop if events.last.fields["drop"]
      end
    end

    @drop = Minitrace::Backend.new do
      use Minitrace::Processors::Spy
      use processor
      use Minitrace::Processors::Spy
    end
  end

  def test_drop
    a = Minitrace::Event.new.add_fields("name" => "a", "drop" => true)
    b = Minitrace::Event.new.add_fields("name" => "b", "drop" => false)
    drop.process(a)
    drop.process(b)
    assert { drop.processors.first.processed == [a, b] }
    assert { drop.processors.last.processed == [b] }
  end

  def head
    @head ||= Minitrace::Backend.new do
      mode :head
      use Minitrace::Processors::Spy
    end
  end

  def test_head
    leaf = Minitrace::Event.new.add_fields(
      "name" => "leaf",
      "trace.trace_id" => "trace",
      "trace.span_id" => "leaf",
      "trace.parent_id" => "root",
      "duration_ms" => 123,
    )
    root = Minitrace::Event.new.add_fields(
      "name" => "root",
      "trace.trace_id" => "trace",
      "trace.span_id" => "root",
      "duration_ms" => 456,
    )

    spy = head.processors.last

    assert { head.mode == :head }

    head.process(leaf)
    assert { spy.processed == [leaf] }

    head.process(leaf)
    assert { spy.processed == [leaf, leaf] }

    head.process(leaf)
    assert { spy.processed == [leaf, leaf, leaf] }

    head.process(root)
    assert { spy.processed == [leaf, leaf, leaf, root] }
  end

  def tail
    @tail ||= Minitrace::Backend.new do
      mode :tail
      use Minitrace::Processors::Spy
    end
  end

  def test_tail
    leaf = Minitrace::Event.new.add_fields(
      "name" => "leaf",
      "trace.trace_id" => "trace",
      "trace.span_id" => "leaf",
      "trace.parent_id" => "root",
      "duration_ms" => 123,
    )
    root = Minitrace::Event.new.add_fields(
      "name" => "root",
      "trace.trace_id" => "trace",
      "trace.span_id" => "root",
      "duration_ms" => 456,
    )

    spy = tail.processors.last

    assert { tail.mode == :tail }

    tail.process(leaf)
    assert { spy.processed == [] }
    assert { tail.buffer == [leaf] }

    tail.process(leaf)
    assert { spy.processed == [] }
    assert { tail.buffer == [leaf, leaf] }

    tail.process(leaf)
    assert { spy.processed == [] }
    assert { tail.buffer == [leaf, leaf, leaf] }

    tail.process(root)
    assert { spy.processed == [leaf, leaf, leaf, root] }
    assert { tail.buffer == [] }
  end

  def test_thread_safety
    a = Minitrace::Event.new.add_fields("name" => "a", "trace.parent_id" => "X")
    b = Minitrace::Event.new.add_fields("name" => "b")
    spy = tail.processors.last

    tail.process(a)
    Thread.new { tail.process(b) }.join

    assert { tail.buffer == [a] }
    assert { spy.processed == [b] }
  end
end
