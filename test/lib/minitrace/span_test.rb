# frozen_string_literal: true

require "test_helper"

class Minitrace::SpanTest < Minitest::Test
  def test_timestamp
    Time.stub(:now, Time.at(123)) do
      span = Minitrace::Span.new
      assert { span.fields["timestamp"] == Time.at(123) }
    end
  end

  def test_fire
    Process.stub(:clock_gettime, ->(*) { @time }) do
      @time = 12.34
      span = Minitrace::Span.new

      @time = 43.21
      span.fire

      assert { processed == [span] }
      assert_in_epsilon 30.87, span.fields["duration_ms"]
    end
  end

  def test_double_fire
    Process.stub(:clock_gettime, ->(*) { @time }) do
      @time = 12.34
      span = Minitrace::Span.new

      @time = 43.21
      span.fire

      @time = 867.5309
      span.fire

      assert { processed == [span] }
      assert_in_epsilon 30.87, span.fields["duration_ms"]
    end
  end

  def test_tracing_root
    root = Minitrace::Span.new

    assert { root.fields["trace.trace_id"] =~ /\A\h{32}\z/ }
    assert { root.fields["trace.span_id"] =~ /\A\h{16}\z/ }
    refute { root.fields.include?("trace.parent_id") }
  end

  def test_tracing_leaf
    root = Minitrace::Span.new
    Minitrace.events << root
    leaf = Minitrace::Span.new

    assert { leaf.fields["trace.trace_id"] =~ /\A\h{32}\z/ }
    assert { leaf.fields["trace.span_id"] =~ /\A\h{16}\z/ }
    assert { leaf.fields["trace.parent_id"] =~ /\A\h{16}\z/ }
    assert { leaf.fields["trace.trace_id"] == root.fields["trace.trace_id"] }
    assert { leaf.fields["trace.parent_id"] == root.fields["trace.span_id"] }
  end

  def test_tracing_from_nonspan_event
    root = Minitrace::Event.new
    Minitrace.events << root
    leaf = Minitrace::Span.new

    assert { leaf.fields["trace.trace_id"] =~ /\A\h{32}\z/ }
    assert { leaf.fields["trace.span_id"] =~ /\A\h{16}\z/ }
    refute { leaf.fields.include?("trace.parent_id") }
    refute { root.fields.include?("trace.trace_id") }
    refute { root.fields.include?("trace.span_id") }
  end
end
