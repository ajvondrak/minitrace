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
end
