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

  def on_error(error)
    add_field("error", error.class.name)
    add_field("error_detail", error.message)
    raise error
  end

  def fired?
    @fired
  end

  def fire
    return if fired?
    Minitrace.backend.process(self)
    @fired = true
  end
end
