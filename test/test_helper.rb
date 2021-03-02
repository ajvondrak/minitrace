# frozen_string_literal: true

require "bundler/setup"
require "minitrace"
Bundler.require(:test)

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

class Minitest::Test
  def before_setup
    Minitrace.backend = Minitrace::Backends::Spy.new
  end

  def after_teardown
    Minitrace.events.clear
  end

  def processed
    Minitrace.backend.processed
  end
end

require "minitest/autorun"
