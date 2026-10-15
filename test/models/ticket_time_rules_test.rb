require "test_helper"

class TicketTimeRulesTest < ActiveSupport::TestCase
  setup do
    @ticket = travel_to(Time.zone.local(2026, 10, 19, 10, 0)) do
      Ticket.create!(subject: "Test", requester_email: "a@example.com").tap { |t| t.transition_to!(:open) }
    end
  end

  test "musteri 7 gun yanit vermezse talep cozulur" do
    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) { @ticket.transition_to!(:pending) }

    travel_to(Time.zone.local(2026, 10, 26, 10, 59)) { Ticket.apply_time_rules! }
    assert_equal "pending", @ticket.reload.status

    travel_to(Time.zone.local(2026, 10, 26, 11, 0)) { Ticket.apply_time_rules! }
    assert_equal "solved", @ticket.reload.status
  end

  test "cozulen talep 4 gun sonra kapanir" do
    travel_to(Time.zone.local(2026, 10, 19, 12, 0)) { @ticket.transition_to!(:solved) }

    travel_to(Time.zone.local(2026, 10, 23, 11, 59)) { Ticket.apply_time_rules! }
    assert_equal "solved", @ticket.reload.status

    travel_to(Time.zone.local(2026, 10, 23, 12, 0)) { Ticket.apply_time_rules! }
    assert_equal "closed", @ticket.reload.status
  end

  test "acik talep zamanla degismez" do
    travel_to(Time.zone.local(2026, 12, 31, 12, 0)) { Ticket.apply_time_rules! }

    assert_equal "open", @ticket.reload.status
  end

  test "otomatik cozulme ve kapanma zamanlari hesaplanir" do
    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) { @ticket.transition_to!(:pending) }
    assert_equal Time.zone.local(2026, 10, 26, 11, 0), @ticket.auto_solve_at

    travel_to(Time.zone.local(2026, 10, 20, 9, 0)) { @ticket.transition_to!(:solved) }
    assert_nil @ticket.auto_solve_at
    assert_equal Time.zone.local(2026, 10, 24, 9, 0), @ticket.auto_close_at
  end
end
