require "test_helper"

# Test raporu bulgu 5: saniyeler son tarihi kaydirmamali.
class SlaSecondsTest < ActiveSupport::TestCase
  test "saniyeli gelis saati son tarihi dakika kaydirmaz" do
    ticket = travel_to(Time.zone.local(2026, 10, 16, 17, 30, 45)) do # Cuma 17:30:45
      Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: :high)
    end

    # Cuma 17:30-18:00 (30 dk) + Pazartesi 09:00'dan 3 sa 30 dk
    assert_equal Time.zone.local(2026, 10, 19, 12, 30), ticket.first_response_due_at
  end
end
