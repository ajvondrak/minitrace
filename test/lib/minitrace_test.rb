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
      Minitrace.with_event { raise error, "jinkies" }
    end
    assert { processed.size == 1 }
    assert { processed.last.fields["error"] == error.name }
    assert { processed.last.fields["error_detail"] == "jinkies" }
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
    assert { processed.empty? }
  end

  def test_disjoint_spans
    Minitrace.with_span("a") { :ok }
    Minitrace.with_span("b") { :ok }

    names = processed.map { |event| event.fields["name"] }
    assert { names == %w[a b] }

    trace_ids = processed.map { |event| event.fields["trace.trace_id"] }
    assert { trace_ids.compact.uniq.size == 2 }

    span_ids = processed.map { |event| event.fields["trace.span_id"] }
    assert { span_ids.compact.uniq.size == span_ids.size }

    a, b = processed.map(&:fields)
    refute { a.include?("trace.parent_id") }
    refute { b.include?("trace.parent_id") }
  end

  def test_nested_spans
    Minitrace.with_span("a") do
      Minitrace.with_span("b") { :ok }
    end

    names = processed.map { |event| event.fields["name"] }
    assert { names == %w[b a] }

    trace_ids = processed.map { |event| event.fields["trace.trace_id"] }
    assert { trace_ids.compact.uniq.size == 1 }

    span_ids = processed.map { |event| event.fields["trace.span_id"] }
    assert { span_ids.compact.uniq.size == span_ids.size }

    b, a = processed.map(&:fields)
    refute { a.include?("trace.parent_id") }
    assert { b["trace.parent_id"] == a["trace.span_id"] }
  end

  def test_nested_disjoint_spans
    Minitrace.with_span("a") do
      Minitrace.with_span("b") { :ok }
      Minitrace.with_span("c") { :ok }
    end

    names = processed.map { |event| event.fields["name"] }
    assert { names == %w[b c a] }

    trace_ids = processed.map { |event| event.fields["trace.trace_id"] }
    assert { trace_ids.compact.uniq.size == 1 }

    span_ids = processed.map { |event| event.fields["trace.span_id"] }
    assert { span_ids.compact.uniq.size == span_ids.size }

    b, c, a = processed.map(&:fields)
    refute { a.include?("trace.parent_id") }
    assert { b["trace.parent_id"] == a["trace.span_id"] }
    assert { c["trace.parent_id"] == a["trace.span_id"] }
  end

  def test_disjoint_nested_spans
    Minitrace.with_span("a") { Minitrace.with_span("b") { :ok } }
    Minitrace.with_span("c") { Minitrace.with_span("d") { :ok } }

    names = processed.map { |event| event.fields["name"] }
    assert { names == %w[b a d c] }

    b, a, d, c = processed.map { |event| event.fields["trace.trace_id"] }
    assert { a == b && c == d && a != c }

    span_ids = processed.map { |event| event.fields["trace.span_id"] }
    assert { span_ids.compact.uniq.size == span_ids.size }

    b, a, d, c = processed.map(&:fields)
    refute { a.include?("trace.parent_id") }
    assert { b["trace.parent_id"] == a["trace.span_id"] }
    refute { c.include?("trace.parent_id") }
    assert { d["trace.parent_id"] == c["trace.span_id"] }
  end

  def test_span_tree
    Minitrace.with_span("root") do
      Minitrace.add_field("type", "root")

      Minitrace.with_span("l") do
        Minitrace.add_field("type", "mid")
        Minitrace.with_span("ll") { Minitrace.add_field("type", "leaf") }
        Minitrace.with_span("lr") { Minitrace.add_field("type", "leaf") }
      end

      Minitrace.with_span("r") do
        Minitrace.add_field("type", "mid")
        Minitrace.with_span("rl") { Minitrace.add_field("type", "leaf") }
        Minitrace.with_span("rr") { Minitrace.add_field("type", "leaf") }
      end
    end

    assert { processed.size == 7 }

    names = processed.map { |event| event.fields["name"] }
    assert { names == %w[ll lr l rl rr r root] }

    types = processed.map { |event| event.fields["type"] }
    assert { types == %w[leaf leaf mid leaf leaf mid root] }

    trace_ids = processed.map { |event| event.fields["trace.trace_id"] }
    assert { trace_ids.compact.uniq.size == 1 }

    span_ids = processed.map { |event| event.fields["trace.span_id"] }
    assert { span_ids.compact.uniq.size == span_ids.size }

    ll, lr, l, rl, rr, r, root = processed.map(&:fields)
    assert { ll["trace.parent_id"] == l["trace.span_id"] }
    assert { lr["trace.parent_id"] == l["trace.span_id"] }
    assert { rl["trace.parent_id"] == r["trace.span_id"] }
    assert { rr["trace.parent_id"] == r["trace.span_id"] }
    assert { l["trace.parent_id"] == root["trace.span_id"] }
    assert { r["trace.parent_id"] == root["trace.span_id"] }
    refute { root.include?("trace.parent_id") }
  end

  def test_async_spans
    Minitrace.span("one").fire
    Minitrace.span("two").fire

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] != two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_before_sync_span
    Minitrace.span("one").fire
    Minitrace.with_span("two") { :ok }

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] != two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_after_sync_span
    Minitrace.with_span("one") { :ok }
    Minitrace.span("two").fire

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] != two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_around_sync_span
    two = Minitrace.span("two")
    Minitrace.with_span("one") { :ok }
    two.fire

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] != two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_within_sync_span
    Minitrace.with_span("two") do
      Minitrace.span("one").fire
    end

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] == two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    assert { one["trace.parent_id"] == two["trace.span_id"] }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_overlapping_before_sync_span
    one = Minitrace.span("one")
    Minitrace.with_span("two") do
      one.fire
    end

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] != two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    refute { two.include?("trace.parent_id") }
  end

  def test_async_span_overlapping_after_sync_span
    two = nil
    Minitrace.with_span("one") do
      two = Minitrace.span("two")
    end
    two.fire

    one, two = processed.map(&:fields)
    assert { one["name"] == "one" && two["name"] == "two" }
    assert { one["trace.trace_id"] == two["trace.trace_id"] }
    assert { one["trace.span_id"] != two["trace.span_id"] }
    refute { one.include?("trace.parent_id") }
    assert { two["trace.parent_id"] == one["trace.span_id"] }
  end

  class Tail < self
    def before_setup
      super
      Minitrace.backend.mode(:tail)
    end

    def test_async_span_overlapping_after_sync_span
      two = nil
      Minitrace.with_span("one") do
        two = Minitrace.span("two")
      end
      two.fire

      assert { processed.size == 1 }
      assert { processed.last.fields["name"] == "one" }

      Minitrace.backend.flush

      assert { processed.size == 2 }
      one, two = processed.map(&:fields)

      assert { one["name"] == "one" && two["name"] == "two" }
      assert { one["trace.trace_id"] == two["trace.trace_id"] }
      assert { one["trace.span_id"] != two["trace.span_id"] }
      refute { one.include?("trace.parent_id") }
      assert { two["trace.parent_id"] == one["trace.span_id"] }
    end
  end
end
