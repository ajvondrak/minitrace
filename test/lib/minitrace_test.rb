# frozen_string_literal: true

require "test_helper"

class MinitraceTest < Minitest::Test
  def test_version
    refute { Minitrace::VERSION.nil? }
  end

  def test_with_event
    returns = Minitrace.with_event { :ok }
    assert { returns == :ok }
    assert { processed.size == 1 }
  end

  def test_with_event_error
    error = Class.new(StandardError)
    assert_raises(error) do
      Minitrace.with_event { raise error }
    end
    assert { processed.size == 1 }
  end

  def test_add_field_outside_of_event
    Minitrace.add_field("field", "value")
    assert { processed.empty? }
  end

  def test_add_fields_outside_of_event
    Minitrace.add_fields("field" => "value")
    assert { processed.empty? }
  end

  def test_add_field_inside_of_event
    Minitrace.with_event { Minitrace.add_field("field", "value") }
    assert { processed.size == 1 }
    assert { processed.last.fields == { "field" => "value" } }
  end

  def test_add_fields_inside_of_event
    Minitrace.with_event { Minitrace.add_fields("field" => "value") }
    assert { processed.size == 1 }
    assert { processed.last.fields == { "field" => "value" } }
  end

  def test_adding_many_fields
    Minitrace.with_event do
      Minitrace.add_field("a", 1)
      Minitrace.add_field("b", 2)
      Minitrace.add_fields("b" => 4, "c" => 6)
      Minitrace.add_field("a", 2)
    end
    assert { processed.size == 1 }
    assert { processed.last.fields == { "a" => 2, "b" => 4, "c" => 6 } }
  end

  def test_disjoint_events
    Minitrace.with_event { Minitrace.add_field("a", 1) }
    Minitrace.with_event { Minitrace.add_field("b", 2) }

    assert { processed.size == 2 }
    assert { processed[0].fields == { "a" => 1 } }
    assert { processed[1].fields == { "b" => 2 } }
  end

  def test_nested_events
    Minitrace.with_event do
      Minitrace.add_field("a", 2)
      Minitrace.with_event do
        Minitrace.add_field("b", 1)
      end
    end

    assert { processed.size == 2 }
    assert { processed[0].fields == { "b" => 1 } }
    assert { processed[1].fields == { "a" => 2 } }
  end

  def test_nested_disjoint_events
    Minitrace.with_event do
      Minitrace.add_field("a", 3)
      Minitrace.with_event { Minitrace.add_field("b", 1) }
      Minitrace.with_event { Minitrace.add_field("c", 2) }
    end

    assert { processed.size == 3 }
    assert { processed[0].fields == { "b" => 1 } }
    assert { processed[1].fields == { "c" => 2 } }
    assert { processed[2].fields == { "a" => 3 } }
  end

  def test_disjoint_nested_events
    Minitrace.with_event do
      Minitrace.add_field("a", 2)
      Minitrace.with_event { Minitrace.add_field("b", 1) }
    end

    Minitrace.with_event do
      Minitrace.add_field("c", 4)
      Minitrace.with_event { Minitrace.add_field("d", 3) }
    end

    assert { processed.size == 4 }
    assert { processed[0].fields == { "b" => 1 } }
    assert { processed[1].fields == { "a" => 2 } }
    assert { processed[2].fields == { "d" => 3 } }
    assert { processed[3].fields == { "c" => 4 } }
  end

  def test_async_event
    async = Minitrace.event
    assert { processed.empty? }
    async.fire
    assert { processed == [async] }
  end

  def test_add_field_is_synchronous
    async = Minitrace.event
    Minitrace.add_field("field", "value")
    assert { async.fields.empty? }
  end

  def test_add_fields_is_synchronous
    async = Minitrace.event
    Minitrace.add_fields("field" => "value")
    assert { async.fields.empty? }
  end

  def test_async_before_sync
    Minitrace.event.add_field("type", "async").fire
    Minitrace.with_event { Minitrace.add_field("type", "sync") }

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "async" } }
    assert { processed[1].fields == { "type" => "sync" } }
  end

  def test_async_after_sync
    Minitrace.with_event { Minitrace.add_field("type", "sync") }
    Minitrace.event.add_field("type", "async").fire

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "sync" } }
    assert { processed[1].fields == { "type" => "async" } }
  end

  def test_async_inside_sync
    Minitrace.with_event do
      Minitrace.add_field("type", "sync")
      Minitrace.event.add_field("type", "async").fire
    end

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "async" } }
    assert { processed[1].fields == { "type" => "sync" } }
  end

  def test_async_outside_sync
    async = Minitrace.event.add_field("type", "async")
    Minitrace.with_event { Minitrace.add_field("type", "sync") }
    async.fire

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "sync" } }
    assert { processed[1].fields == { "type" => "async" } }
  end

  def test_async_overlap_sync_before
    async = Minitrace.event.add_field("type", "async")
    Minitrace.with_event do
      Minitrace.add_field("type", "sync")
      async.fire
    end

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "async" } }
    assert { processed[1].fields == { "type" => "sync" } }
  end

  def test_async_overlap_sync_after
    async = nil
    Minitrace.with_event do
      async = Minitrace.event.add_field("type", "async")
      Minitrace.add_field("type", "sync")
    end
    async.fire

    assert { processed.size == 2 }
    assert { processed[0].fields == { "type" => "sync" } }
    assert { processed[1].fields == { "type" => "async" } }
  end

  def test_thread_safety
    Minitrace.with_event do
      Minitrace.add_field("thread", "safe")
      Thread.new { Minitrace.add_field("thread", "unsafe") }.join
    end

    assert { processed.size == 1 }
    assert { processed.last.fields["thread"] == "safe" }
  end

  def test_sync_error
    assert_raises(Minitrace::SyncError) do
      Minitrace.with_event do
        # Let's say that somehow this happens
        Minitrace.events << Minitrace.event
      end
    end
  end
end
