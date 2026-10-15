require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "temsilci yanit yazar" do
    sign_in_as(users(:one))
    ticket = tickets(:new_ticket)

    assert_difference("Comment.count", 1) do
      post ticket_comments_url(ticket), params: { comment: { body: "Merhaba", internal: "0" } }
    end

    assert_redirected_to ticket_url(ticket)
    assert_not_nil ticket.reload.first_responded_at
  end

  test "temsilci ic not yazar, ilk yanit sayilmaz" do
    sign_in_as(users(:one))
    ticket = tickets(:new_ticket)

    post ticket_comments_url(ticket), params: { comment: { body: "Not", internal: "1" } }

    assert Comment.last.internal
    assert_nil ticket.reload.first_responded_at
  end

  test "giris yapmadan yanit yazilamaz" do
    assert_no_difference("Comment.count") do
      post ticket_comments_url(tickets(:new_ticket)), params: { comment: { body: "Merhaba" } }
    end

    assert_redirected_to new_session_url
  end
end
