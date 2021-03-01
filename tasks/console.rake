desc "Run a console with minitrace loaded"
task :console do
  require "bundler/setup"
  require "minitrace"
  require "pry"
  Pry.start
end
