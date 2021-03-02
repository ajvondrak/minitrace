# frozen_string_literal: true

class Minitrace::Event
  attr_reader :fields

  def initialize
    @fields = {}
  end

  def add_field(field, value)
    @fields[field] = value
    self
  end

  def add_fields(fields)
    @fields.merge!(fields)
    self
  end

  def fire
    return if @fired
    Minitrace.backend.process(self)
    @fired = true
  end
end
