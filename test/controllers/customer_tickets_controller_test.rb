require "test_helper"

# Musterinin gizli linkli talep sayfasi: /t/:token
class CustomerTicketsControllerTest < ActionDispatch::IntegrationTest
  test "talep acan musteri kendi talep sayfasina yonlendirilir" do
    post tickets_url, params: { ticket: { subject: "Kargom gelmedi", requester_email: "can@example.com", priority: "normal" } }

    ticket = Ticket.last
    assert_redirected_to customer_ticket_url(ticket.access_token)
    follow_redirect!
    assert_response :success
    assert_match "Kargom gelmedi", response.body
    assert_match "Bu sayfa size özel", response.body
  end

  test "musteri giris yapmadan talebini ve herkese acik yanitlari gorur, ic notu goremez" do
    get customer_ticket_url(tickets(:open_ticket).access_token)

    assert_response :success
    assert_match comments(:open_ticket_reply).body, response.body
    assert_no_match comments(:open_ticket_internal_note).body, response.body
    assert_match "Destek ekibi", response.body
    assert_no_match users(:one).email_address, response.body
  end

  test "yanlis anahtarla talep gorulemez" do
    get customer_ticket_url("yanlisAnahtar123456789012")

    assert_response :not_found
  end

  test "link baska sitelere sizdirilmaz ve indekslenmez" do
    get customer_ticket_url(tickets(:open_ticket).access_token)

    assert_equal "no-referrer", response.headers["Referrer-Policy"]
    assert_match "noindex", response.headers["X-Robots-Tag"]
  end

  test "musteri yaniti talebe eklenir; musteri bekleniyorsa talep yeniden acilir" do
    ticket = tickets(:open_ticket)
    ticket.transition_to!(:pending)

    assert_difference("ticket.comments.count", 1) do
      post customer_ticket_reply_url(ticket.access_token), params: { reply: { body: "Fotografi ekledim." } }
    end

    assert_redirected_to customer_ticket_url(ticket.access_token)
    comment = ticket.comments.order(:created_at).last
    assert comment.from_customer?
    assert_not comment.internal
    assert_equal "open", ticket.reload.status
  end

  test "temsilci musteri yanitini talep sayfasinda gorur" do
    ticket = tickets(:open_ticket)
    post customer_ticket_reply_url(ticket.access_token), params: { reply: { body: "Hala calismiyor." } }

    sign_in_as(users(:one))
    get ticket_url(ticket)

    assert_match "Hala calismiyor.", response.body
    assert_match "Müşteri yanıtı", response.body
  end

  test "kapali talebe musteri yanit yazamaz" do
    ticket = tickets(:closed_ticket)

    assert_no_difference("Comment.count") do
      post customer_ticket_reply_url(ticket.access_token), params: { reply: { body: "Merhaba" } }
    end

    follow_redirect!
    assert_match "Kapalı talebe yanıt yazılamaz", response.body
  end

  test "bos yanit kaydedilmez" do
    ticket = tickets(:open_ticket)

    assert_no_difference("Comment.count") do
      post customer_ticket_reply_url(ticket.access_token), params: { reply: { body: "" } }
    end

    assert_redirected_to customer_ticket_url(ticket.access_token)
  end

  test "yanlis anahtarla yanit yazilamaz" do
    assert_no_difference("Comment.count") do
      post customer_ticket_reply_url("yanlisAnahtar123456789012"), params: { reply: { body: "Merhaba" } }
    end

    assert_response :not_found
  end
end
