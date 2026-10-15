require "test_helper"

# Ilk yanit SLA'si: is takvimi (Pzt-Cuma 09-18, Istanbul), resmi tatiller ve on_hold duraklatmasi.
class TicketSlaTest < ActiveSupport::TestCase
  def create_ticket(priority, at:)
    travel_to(at) { Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: priority) }
  end

  test "cuma aksami gelen yuksek oncelikli talep: hafta sonu sayilmaz" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 16, 17, 30)) # Cuma 17:30, hedef 4 sa

    # Cuma 30 dk + Pazartesi 09:00'dan 3 sa 30 dk
    assert_equal Time.zone.local(2026, 10, 19, 12, 30), ticket.first_response_due_at
  end

  test "resmi tatil sayilmaz" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 28, 17, 0)) # Carsamba 17:00

    # Carsamba 1 sa + 29 Ekim (Persembe) tatil + Cuma 09:00'dan 3 sa
    assert_equal Time.zone.local(2026, 10, 30, 12, 0), ticket.first_response_due_at
  end

  test "hafta sonu gelen normal talep pazartesi mesaisinde dolar" do
    ticket = create_ticket(:normal, at: Time.zone.local(2026, 10, 17, 10, 0)) # Cumartesi, hedef 8 sa

    assert_equal Time.zone.local(2026, 10, 19, 17, 0), ticket.first_response_due_at
  end

  test "on_hold'da sayac durur, acilinca kalan sureden devam eder" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 19, 9, 0)) # Pazartesi 09:00 -> 13:00
    travel_to(Time.zone.local(2026, 10, 19, 9, 0)) { ticket.transition_to!(:open) }

    travel_to(Time.zone.local(2026, 10, 19, 10, 0)) { ticket.transition_to!(:on_hold) }
    assert_nil ticket.reload.first_response_due_at
    assert_equal :paused, ticket.sla_state

    travel_to(Time.zone.local(2026, 10, 19, 12, 0)) { ticket.transition_to!(:open) }
    # 1 sa harcanmisti, 3 sa kaldi: 12:00 + 3 sa
    assert_equal Time.zone.local(2026, 10, 19, 15, 0), ticket.reload.first_response_due_at
  end

  test "beklemede iken sure gecse de ihlal sayilmaz" do
    ticket = create_ticket(:urgent, at: Time.zone.local(2026, 10, 19, 9, 0)) # hedef 10:00
    travel_to(Time.zone.local(2026, 10, 19, 9, 10)) { ticket.transition_to!(:open) }
    travel_to(Time.zone.local(2026, 10, 19, 9, 20)) { ticket.transition_to!(:on_hold) }

    travel_to(Time.zone.local(2026, 10, 19, 16, 0)) do
      assert_equal :paused, ticket.reload.sla_state
    end
  end

  test "yanit verilmeden sure gecerse ihlal olur" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 19, 9, 0)) # 13:00

    travel_to(Time.zone.local(2026, 10, 19, 12, 59)) { assert_equal :running, ticket.sla_state }
    travel_to(Time.zone.local(2026, 10, 19, 13, 1)) do
      assert_equal :breached, ticket.sla_state
      assert_includes Ticket.sla_breached, ticket
    end
  end

  test "zamaninda verilen ilk yanit SLA'yi karsilar" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 19, 9, 0))

    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) { ticket.add_reply!(author: users(:one), body: "Bakiyoruz") }

    assert_equal :met, ticket.reload.sla_state
  end

  test "gec verilen ilk yanit ihlal olarak kalir" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 19, 9, 0))

    travel_to(Time.zone.local(2026, 10, 19, 14, 0)) { ticket.add_reply!(author: users(:one), body: "Gecikme icin ozur") }

    assert_equal :breached, ticket.reload.sla_state
  end

  test "SLA aciklamasi tatili adim adim gosterir" do
    ticket = create_ticket(:high, at: Time.zone.local(2026, 10, 28, 17, 0))
    steps = SlaClock.new(ticket).compute.steps

    assert_equal %i[start work skip work due], steps.map { |step| step[:kind] }
    assert_equal [ "Cumhuriyet Bayramı" ], steps.filter_map { |step| step[:reason] }
  end
end
