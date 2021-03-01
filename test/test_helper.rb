# frozen_string_literal: true

require "bundler/setup"
Bundler.require(:test)

Minitest::Reporters.use! Minitest::Reporters::DefaultReporter.new

require "minitest/autorun"
require "minitrace"
