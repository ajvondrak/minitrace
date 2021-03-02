# frozen_string_literal: true

class Minitrace::Backends::Spy < Minitrace::Backend
  def processed
    @processed ||= []
  end

  def process(event)
    processed << event
  end
end
