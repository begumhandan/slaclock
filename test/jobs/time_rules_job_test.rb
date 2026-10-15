require "test_helper"

class TimeRulesJobTest < ActiveJob::TestCase
  test "job zaman kurallarini uygular" do
    ticket = travel_to(Time.zone.local(2026, 10, 19, 10, 0)) do
      Ticket.create!(subject: "Test", requester_email: "a@example.com").tap do |t|
        t.transition_to!(:open)
        t.transition_to!(:solved)
      end
    end

    travel_to(Time.zone.local(2026, 10, 24, 10, 0)) { TimeRulesJob.perform_now }

    assert_equal "closed", ticket.reload.status
  end
end
