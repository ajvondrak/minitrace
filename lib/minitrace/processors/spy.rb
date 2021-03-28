# frozen_string_literal: true

class Minitrace::Processors::Spy
  def processed
    @processed ||= []
  end

  def process(events)
    processed.append(*events)
  end
end
