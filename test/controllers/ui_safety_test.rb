require "test_helper"

# Test raporu bulgulari 7, 8, 9.
class UiSafetyTest < ActionDispatch::IntegrationTest
  test "giris yapan temsilci kuyruga yonlenir" do
    post session_path, params: { email_address: users(:one).email_address, password: "password" }

    assert_redirected_to tickets_url
  end

  test "Kapandi dugmesi onay ister" do
    sign_in_as(users(:one))
    ticket = travel_to(1.hour.ago) { Ticket.create!(subject: "Test", requester_email: "a@example.com") }
    ticket.transition_to!(:open)
    ticket.transition_to!(:solved)

    get ticket_url(ticket)

    assert_match "data-turbo-confirm", response.body
  end

  test "ayni adresten dakikada 5'ten fazla talep acilamaz" do
    params = { ticket: { subject: "Spam", requester_email: "bot@example.com", priority: "low" } }

    assert_difference("Ticket.count", 5) do
      6.times { post tickets_url, params: params }
    end
    assert_redirected_to new_ticket_url
    assert_equal "Çok fazla talep gönderdiniz. Bir dakika sonra tekrar deneyin.", flash[:alert]
  end
end
