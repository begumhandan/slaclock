require "test_helper"

# Musteri yaniti (gizli linkten) ve musteri sayfasinin anahtari.
class TicketCustomerReplyTest < ActiveSupport::TestCase
  setup do
    @ticket = travel_to(Time.zone.local(2026, 10, 19, 10, 0)) do
      Ticket.create!(subject: "Test", requester_email: "a@example.com", priority: "normal")
    end
  end

  test "her talebe tahmin edilemeyen, benzersiz bir anahtar verilir" do
    other = Ticket.create!(subject: "Diger", requester_email: "b@example.com")

    assert_operator @ticket.access_token.length, :>=, 24
    assert_not_equal @ticket.access_token, other.access_token
  end

  test "musteri yaniti ilk yanit sayilmaz, SLA isler" do
    due = @ticket.first_response_due_at

    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) { @ticket.add_customer_reply!(body: "Ek bilgi") }

    @ticket.reload
    assert_nil @ticket.first_responded_at
    assert_equal due, @ticket.first_response_due_at
    assert_equal "new", @ticket.status
  end

  test "cozulmus talebe musteri yazarsa talep yeniden acilir" do
    @ticket.add_reply!(author: users(:one), body: "Cozuldu")
    @ticket.transition_to!(:solved)

    @ticket.add_customer_reply!(body: "Hala olmuyor")

    assert_equal "open", @ticket.reload.status
    assert_nil @ticket.solved_at
  end

  test "beklemedeki (3. taraf) talep musteri yazinca beklemede kalir" do
    @ticket.add_reply!(author: users(:one), body: "Kargoya sorduk")
    @ticket.transition_to!(:on_hold)

    @ticket.add_customer_reply!(body: "Tesekkurler")

    assert_equal "on_hold", @ticket.reload.status
  end

  test "musteri 7 gun dolmadan yanit verirse talep otomatik cozulmez" do
    travel_to(Time.zone.local(2026, 10, 19, 11, 0)) do
      @ticket.add_reply!(author: users(:one), body: "Fotograf gonderir misiniz?")
      @ticket.transition_to!(:pending)
    end

    travel_to(Time.zone.local(2026, 10, 25, 11, 0)) { @ticket.add_customer_reply!(body: "Gonderdim") }
    assert_equal "open", @ticket.reload.status

    travel_to(Time.zone.local(2026, 10, 27, 11, 0)) { Ticket.apply_time_rules! }
    assert_equal "open", @ticket.reload.status
  end

  test "kapali talebe musteri yanit yazamaz" do
    ticket = tickets(:closed_ticket)

    assert_raises(Ticket::InvalidTransition) { ticket.add_customer_reply!(body: "Merhaba") }
    assert_equal 0, ticket.comments.count
  end
end
