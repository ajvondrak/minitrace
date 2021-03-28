# frozen_string_literal: true

class Minitrace::Processors::Spy
  def processed
    @processed ||= []
  end

  def process(event)
    processed << event
  end
end
