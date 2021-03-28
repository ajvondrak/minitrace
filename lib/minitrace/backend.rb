# frozen_string_literal: true

require "minitrace/processors"

class Minitrace::Backend
  attr_reader :processors

  def initialize(&block)
    @processors = []
    instance_eval(&block)
  end

  def use(processor, *args, **opts, &block)
    processors << processor.new(*args, **opts, &block)
  end

  def process(event)
    processors.each do |processor|
      processor.process(event)
    end
  end
end
