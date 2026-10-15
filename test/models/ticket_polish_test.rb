require "test_helper"

# Test raporu bulgulari 10 ve 12.
class TicketPolishTest < ActiveSupport::TestCase
  test "yasak gecis mesaji ekrandaki durum adlarini kullanir" do
    error = assert_raises(Ticket::InvalidTransition) { tickets(:closed_ticket).transition_to!(:open) }

    assert_equal "Kapandı durumundan Açık durumuna geçilemez.", error.message
  end

  test "bilinmeyen durum adi anlasilir mesaj verir" do
    error = assert_raises(Ticket::InvalidTransition) { tickets(:new_ticket).transition_to!("uydurma") }

    assert_equal "Yeni durumundan bilinmeyen bir durum durumuna geçilemez.", error.message
  end

  test "talep sahibinin e-postasi bosluklardan arindirilip kucuk harfe cevrilir" do
    ticket = Ticket.create!(subject: "Test", requester_email: "  Ayse@Example.COM ")

    assert_equal "ayse@example.com", ticket.requester_email
  end

  test "cok uzun konu ve aciklama kabul edilmez" do
    ticket = Ticket.new(subject: "a" * 201, body: "b" * 10_001, requester_email: "a@example.com")

    assert_not ticket.valid?
    assert ticket.errors.key?(:subject)
    assert ticket.errors.key?(:body)
  end
end
