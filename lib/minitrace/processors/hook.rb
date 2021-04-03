# frozen_string_literal: true

class Minitrace::Processors::Hook
  def initialize(&hook)
    @hook = hook
  end

  def process(events)
    events.each { |event| @hook.call(event) }
  end
end
