require "test_helper"

class ClosedTicketGuardTest < ActionDispatch::IntegrationTest
  setup { sign_in_as(users(:one)) }

  test "kapali talebe dogrudan istekle yanit yazilamaz" do
    ticket = tickets(:closed_ticket)

    assert_no_difference("Comment.count") do
      post ticket_comments_url(ticket), params: { comment: { body: "Sizi aradik", internal: "0" } }
    end

    assert_redirected_to ticket_url(ticket)
    assert_equal "Kapalı talepte işlem yapılamaz", flash[:alert]
  end

  test "kapali talep dogrudan istekle atanamaz" do
    ticket = tickets(:closed_ticket)

    patch assign_to_me_ticket_url(ticket)

    assert_redirected_to ticket_url(ticket)
    assert_nil ticket.reload.assignee
  end

  test "kapali talepte Bana ata dugmesi gorunmez" do
    get ticket_url(tickets(:closed_ticket))

    assert_response :success
    assert_no_match "Bana ata", response.body
  end
end
