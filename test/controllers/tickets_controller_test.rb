require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  test "musteri giris yapmadan talep formunu acar" do
    get new_ticket_url
    assert_response :success
  end

  test "musteri giris yapmadan talep acar" do
    assert_difference("Ticket.count", 1) do
      post tickets_url, params: { ticket: { subject: "Yardim", requester_email: "a@example.com", priority: "high" } }
    end

    ticket = Ticket.last
    assert_redirected_to customer_ticket_url(ticket.access_token)
    assert_equal "new", ticket.status
  end

  test "eksik bilgili talep kaydedilmez" do
    assert_no_difference("Ticket.count") do
      post tickets_url, params: { ticket: { subject: "", requester_email: "" } }
    end

    assert_response :unprocessable_content
  end

  test "talep listesi giris ister" do
    get tickets_url
    assert_redirected_to new_session_url
  end

  test "temsilci talep listesini gorur" do
    sign_in_as(users(:one))

    get tickets_url

    assert_response :success
    assert_match tickets(:new_ticket).subject, response.body
  end

  test "temsilci listeyi acinca zaman kurallari uygulanir" do
    # Render ucretsiz plani uyudugu icin canlida kurallari liste sayfasi calistirir (bkz. AGENT.md).
    ticket = travel_to(8.days.ago) do
      Ticket.create!(subject: "Eski bekleyen", requester_email: "a@example.com").tap do |t|
        t.transition_to!(:open)
        t.transition_to!(:pending)
      end
    end

    sign_in_as(users(:one))
    get tickets_url

    assert_equal "solved", ticket.reload.status
  end

  test "temsilci talebi kendine atayinca yeni talep acik olur" do
    sign_in_as(users(:one))
    ticket = tickets(:new_ticket)

    patch assign_to_me_ticket_url(ticket)

    assert_redirected_to ticket_url(ticket)
    assert_equal users(:one), ticket.reload.assignee
    assert_equal "open", ticket.status
  end

  test "izinli gecis ekrandan yapilir" do
    sign_in_as(users(:one))
    ticket = tickets(:open_ticket)

    patch transition_ticket_url(ticket, to: "on_hold")

    assert_equal "on_hold", ticket.reload.status
  end

  test "yasak gecis ekrandan yapilamaz, hata mesaji gosterilir" do
    sign_in_as(users(:one))
    ticket = tickets(:closed_ticket)

    patch transition_ticket_url(ticket, to: "open")
    follow_redirect!

    assert_equal "closed", ticket.reload.status
    assert_match "Kapandı durumundan Açık durumuna geçilemez.", response.body
  end
end
