# frozen_string_literal: true

require "test_helper"

class Minitrace::BackendTest < Minitest::Test
  def backend
    @backend ||= Minitrace::Backend.new do
      use Minitrace::Processors::Spy
      use Minitrace::Processors::Spy
      use Minitrace::Processors::Spy
    end
  end

  def test_basic
    event = Minitrace::Event.new
    backend.process(event)
    backend.processors.each do |spy|
      assert { spy.processed == [event] }
    end
  end
end
