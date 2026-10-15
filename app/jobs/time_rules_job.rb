# Zaman kurallarini uygular (pending -> solved, solved -> closed). Bkz. Ticket.apply_time_rules!
class TimeRulesJob < ApplicationJob
  queue_as :default

  def perform
    Ticket.apply_time_rules!
  end
end
