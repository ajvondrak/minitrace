# frozen_string_literal: true

require 'test_helper'

class MinitraceTest < Minitest::Test
  def test_version
    refute { Minitrace::VERSION.nil? }
  end
end
