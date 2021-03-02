# frozen_string_literal: true

class Minitrace::Backend
  def process(event)
    raise NotImplementedError
  end
end
