# frozen_string_literal: true

module Minitrace::Processors
  autoload :Spy, "minitrace/processors/spy"
  autoload :Honeycomb, "minitrace/processors/honeycomb"
  autoload :Sampling, "minitrace/processors/sampling"
  autoload :Hook, "minitrace/processors/hook"
end
