require "test_helper"

class TicketAssignTest < ActiveSupport::TestCase
  test "yeni talep atandiginda open olur" do
    ticket = tickets(:new_ticket)

    ticket.assign_to!(users(:two))

    assert_equal users(:two), ticket.reload.assignee
    assert_equal "open", ticket.status
  end

  test "acik talep baskasina atandiginda durumu degismez" do
    ticket = tickets(:open_ticket)

    ticket.assign_to!(users(:two))

    assert_equal users(:two), ticket.reload.assignee
    assert_equal "open", ticket.status
  end
end
