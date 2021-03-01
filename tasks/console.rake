# frozen_string_literal: true

desc "Run a console with minitrace loaded"
task :console do
  require "bundler/setup"
  require "minitrace"
  require "pry"
  Pry.start
end
