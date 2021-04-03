# frozen_string_literal: true

require "minitrace/processors"

class Minitrace::Backend
  attr_reader :processors

  def initialize(&block)
    @mode = :head
    @processors = []
    instance_eval(&block)
    at_exit { flush }
  end

  def mode(mode = nil)
    return @mode if mode.nil?
    @mode = mode
  end

  def use(processor, *args, &block)
    processors << processor.new(*args, &block)
  end

  def process(event)
    case @mode
    when :head
      handle([event])
    when :tail
      buffer << event
      flush if flush?
    end
  end

  def buffer
    Thread.current["#{self.class}:buffer:#{object_id}"] ||= []
  end

  def flush?
    !buffer.empty? && !buffer.last.fields.include?("trace.parent_id")
  end

  def flush
    return if buffer.empty?
    handle(buffer)
    buffer.clear
  end

  private

  def handle(events)
    catch(:drop) do
      processors.each do |processor|
        processor.process(events)
      end
    end
  end
end
