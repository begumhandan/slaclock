require "test_helper"

class TicketTest < ActiveSupport::TestCase
  test "yeni talep new durumunda ve normal oncelikte baslar" do
    ticket = Ticket.create!(subject: "Yardim", requester_email: "a@example.com")

    assert_equal "new", ticket.status
    assert_equal "normal", ticket.priority
  end

  test "talep sahibinin e-postasi zorunludur" do
    ticket = Ticket.new(subject: "Yardim")

    assert_not ticket.valid?
    assert ticket.errors.key?(:requester_email)
  end

  test "mutlu yol: new > open > pending > open > on_hold > open > solved > closed" do
    ticket = tickets(:new_ticket)

    %w[open pending open on_hold open solved closed].each do |target|
      ticket.transition_to!(target)
      assert_equal target, ticket.reload.status
    end
  end

  test "cozulunce solved_at yazilir, yeniden acilinca silinir" do
    ticket = tickets(:open_ticket)

    travel_to Time.zone.local(2026, 10, 16, 10, 0) do
      ticket.transition_to!(:solved)
      assert_equal Time.zone.local(2026, 10, 16, 10, 0), ticket.reload.solved_at
    end

    ticket.transition_to!(:open)
    assert_nil ticket.reload.solved_at
  end

  test "solved! gibi korumasiz enum metotlari yoktur" do
    assert_not tickets(:new_ticket).respond_to?(:solved!)
  end

  # Yasak gecisler TRANSITIONS tablosundan uretilir: tabloda olmayan HER gecisin ayri testi var.
  # Tablo degisirse testler de kendiliginden degisir (bkz. AGENT.md, "Her yasak gecisin bir testi vardir").
  STATUSES = Ticket.statuses.keys

  STATUSES.each do |from|
    (STATUSES - [ from ] - Ticket::TRANSITIONS.fetch(from)).each do |to|
      test "yasak gecis: #{from} -> #{to}" do
        ticket = Ticket.create!(subject: "Yasak gecis", requester_email: "a@example.com")
        ticket.update_columns(status: Ticket.statuses.fetch(from))

        assert_raises(Ticket::InvalidTransition) { ticket.transition_to!(to) }
        assert_equal from, ticket.reload.status
      end
    end
  end

  test "yasak gecis sayisi tabloyla tutarli" do
    allowed = Ticket::TRANSITIONS.values.sum(&:size)
    assert_equal 9, allowed
    assert_equal 21, STATUSES.size * (STATUSES.size - 1) - allowed
  end
end
