require "test_helper"

# Test raporu (15 Ekim) bulgulari 2 ve 3.
class TicketGuardsTest < ActiveSupport::TestCase
  test "kapali talebe yanit yazilamaz" do
    ticket = tickets(:closed_ticket)

    assert_raises(Ticket::InvalidTransition) { ticket.add_reply!(author: users(:one), body: "Merhaba") }
    assert_equal 0, ticket.comments.count
    assert_nil ticket.reload.first_responded_at
  end

  test "kapali talep atanamaz" do
    ticket = tickets(:closed_ticket)

    assert_raises(Ticket::InvalidTransition) { ticket.assign_to!(users(:one)) }
    assert_nil ticket.reload.assignee
  end

  test "ilk yanittan sonra beklemeye alinan talebin son tarihi degismez" do
    ticket = travel_to(Time.zone.local(2026, 10, 19, 9, 0)) do
      Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: :high) # son tarih 13:00
    end
    travel_to(Time.zone.local(2026, 10, 19, 10, 0)) { ticket.add_reply!(author: users(:one), body: "Bakiyoruz") }
    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) { ticket.transition_to!(:on_hold) }

    assert_equal Time.zone.local(2026, 10, 19, 13, 0), ticket.reload.first_response_due_at
    assert_equal :met, ticket.sla_state

    travel_to(Time.zone.local(2026, 10, 19, 15, 0)) { ticket.transition_to!(:open) }
    assert_equal Time.zone.local(2026, 10, 19, 13, 0), ticket.reload.first_response_due_at
    assert_not SlaClock.new(ticket).compute.steps.any? { |step| step[:kind] == :pause }
  end

  test "yanittan once baslayan bekleme son tarihi uzatmaya devam eder" do
    ticket = travel_to(Time.zone.local(2026, 10, 19, 9, 0)) do
      Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: :high)
    end
    travel_to(Time.zone.local(2026, 10, 19, 9, 5)) { ticket.transition_to!(:open) }
    travel_to(Time.zone.local(2026, 10, 19, 10, 0)) { ticket.transition_to!(:on_hold) }
    travel_to(Time.zone.local(2026, 10, 19, 12, 0)) { ticket.transition_to!(:open) }
    travel_to(Time.zone.local(2026, 10, 19, 12, 30)) { ticket.add_reply!(author: users(:one), body: "Cozduk") }

    assert_equal Time.zone.local(2026, 10, 19, 15, 0), ticket.reload.first_response_due_at
    assert_equal :met, ticket.sla_state
  end
end
