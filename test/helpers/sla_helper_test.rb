require "test_helper"

class SlaHelperTest < ActionView::TestCase
  include TicketsHelper

  def solved_ticket(created:, solved:, priority: :high)
    ticket = travel_to(created) { Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: priority) }
    travel_to(created + 1.minute) { ticket.transition_to!(:open) }
    travel_to(solved) { ticket.transition_to!(:solved) }
    ticket
  end

  test "yanit verilmeden suresi icinde cozulen talep 'zamaninda yanitlandi' demez" do
    ticket = solved_ticket(created: Time.zone.local(2026, 10, 19, 9, 0), solved: Time.zone.local(2026, 10, 19, 10, 0))

    info = travel_to(Time.zone.local(2026, 10, 19, 16, 0)) { sla_info(ticket) }

    assert_equal :met, info[:state]
    assert_equal "Yanıt gerekmeden çözüldü", info[:text]
  end

  test "yanitsiz ve gec cozulen talepte gecikme cozulme aninda donar" do
    # Son tarih 13:00, 14:00'te cozuldu: 1 sa gecikme. Ertesi gun bakinca da 1 sa kalmali.
    ticket = solved_ticket(created: Time.zone.local(2026, 10, 19, 9, 0), solved: Time.zone.local(2026, 10, 19, 14, 0))

    info = travel_to(Time.zone.local(2026, 10, 20, 17, 0)) { sla_info(ticket) }

    assert_equal :breached, info[:state]
    assert_equal "Yanıtlanmadan çözüldü, 1 sa gecikti", info[:text]
  end
end
