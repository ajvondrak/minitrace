# frozen_string_literal: true

module Minitrace::Integrations
  def self.require(gem)
    Kernel.require(gem)
  rescue LoadError
    raise "Could not load the #{gem} gem. Use `gem install #{gem}` to install."
  end
end
