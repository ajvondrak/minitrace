# frozen_string_literal: true

require "test_helper"

class Minitrace::Processors::SpyTest < Minitest::Test
  def test_process
    spy = Minitrace::Processors::Spy.new

    a = Minitrace::Event.new
    spy.process(a)

    b = Minitrace::Event.new
    spy.process(b)

    c = Minitrace::Event.new
    spy.process(c)

    assert { spy.processed == [a, b, c] }
  end
end
