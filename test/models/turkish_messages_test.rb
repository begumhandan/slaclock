require "test_helper"

# Test raporu bulgu 6: hata mesajlari Turkce.
class TurkishMessagesTest < ActiveSupport::TestCase
  test "talep dogrulama mesajlari Turkce" do
    ticket = Ticket.new(subject: "", requester_email: "gecersiz")

    assert_not ticket.valid?
    assert_includes ticket.errors.full_messages, "Konu boş bırakılamaz"
    assert_includes ticket.errors.full_messages, "E-posta adresi geçersiz"
  end
end
