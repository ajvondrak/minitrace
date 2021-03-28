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
end
