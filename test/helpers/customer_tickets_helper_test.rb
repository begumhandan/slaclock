require "test_helper"

# Musterinin gordugu durum adlari ve aciklama cumlesi her durumda hatasiz uretilir.
class CustomerTicketsHelperTest < ActionView::TestCase
  include SlaHelper

  test "her durum icin musteri diliyle ad ve aciklama var" do
    Ticket::STATUS_LABELS.each_key do |status|
      ticket = Ticket.new(status: status, first_response_due_at: Time.zone.local(2026, 10, 19, 10, 0))

      assert_match CustomerTicketsHelper::CUSTOMER_STATUS_LABELS.fetch(status), customer_status_chip(status)
      assert customer_status_note(ticket).present?, "#{status} icin aciklama bos"
    end
  end

  test "musteri bekleniyor durumunda otomatik cozulme tarihi yazilir" do
    ticket = Ticket.new(status: "pending", status_changed_at: Time.zone.local(2026, 10, 19, 11, 0))

    assert_match "26 Ekim Pazartesi 11:00", customer_status_note(ticket)
  end

  test "temsilci dili musteriye gosterilmez" do
    assert_no_match "Müşteri bekleniyor", customer_status_chip("pending")
    assert_match "Yanıtınız bekleniyor", customer_status_chip("pending")
  end
end
