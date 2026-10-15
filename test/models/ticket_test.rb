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

  # Yasak gecisler: her biri ayri test, durum degismeden kalmali.
  {
    new_ticket: %w[pending on_hold solved closed],
    open_ticket: %w[new closed],
    closed_ticket: %w[new open pending on_hold solved]
  }.each do |fixture, targets|
    targets.each do |target|
      test "yasak gecis: #{fixture} -> #{target}" do
        ticket = tickets(fixture)
        before = ticket.status

        assert_raises(Ticket::InvalidTransition) { ticket.transition_to!(target) }
        assert_equal before, ticket.reload.status
      end
    end
  end
end
