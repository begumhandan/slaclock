require "test_helper"

class TicketPrivacyTest < ActiveSupport::TestCase
  def create_ticket(**attrs)
    Ticket.create!({ subject: "Siparişim gelmedi", requester_email: "begum@example.com", requester_name: "Begüm Demir",
                     birth_year: 2004, occupation: "Yazılım mühendisliği öğrencisi", city: "Samsun",
                     body: "Ben Begüm Demir, telefonum 0532 123 45 67, TC 12345678901." }.merge(attrs))
  end

  test "talep acilinca persona ve maskeli metin kaydedilir" do
    ticket = create_ticket

    assert ticket.persona_name.present?
    assert_match "mühendislik öğrencisi · Samsun", ticket.persona_summary
    assert_no_match(/Begüm|0532|12345678901/, ticket.agent_body)
    assert_includes ticket.agent_body, "[TELEFON]"
    assert_includes ticket.agent_body, ticket.persona_name
  end

  test "musteri yanitinin da maskeli hali saklanir" do
    ticket = create_ticket
    comment = ticket.add_customer_reply!(body: "Yeni numaram 0555 222 33 44")

    assert_equal "Yeni numaram [TELEFON]", comment.agent_body
    assert_equal "Yeni numaram 0555 222 33 44", comment.body
  end

  test "temsilcinin persona adiyla hitabi musteriye gercek adiyla gosterilir" do
    ticket = create_ticket
    persona_first = ticket.persona_name.split.first

    assert_equal "Merhaba Begüm, kargonuz yolda.", ticket.unmask_for_customer("Merhaba #{persona_first}, kargonuz yolda.")
  end

  test "dogum yili makul araliktadir" do
    assert_not Ticket.new(subject: "x", requester_email: "a@example.com", birth_year: 1800).valid?
  end
end
