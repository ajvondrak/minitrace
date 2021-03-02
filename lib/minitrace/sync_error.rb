# frozen_string_literal: true

class Minitrace::SyncError < RuntimeError
  ISSUE = <<-ISSUE
  You've discovered a Minitrace bug!

  Minitrace attempted to fire a synchronous event that it wasn't expecting, so
  methods like Minitrace.add_field may have corrupted some events' fields.

  Please open an issue on GitHub with the stack trace and any other details you
  can provide: https://github.com/ajvondrak/minitrace/issues/new
  ISSUE

  def initialize(event, pending)
    super("Expected #{event.inspect}, got #{pending.inspect}\n\n#{ISSUE}")
  end
end
