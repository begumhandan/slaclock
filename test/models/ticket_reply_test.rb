require "test_helper"

class TicketReplyTest < ActiveSupport::TestCase
  test "ilk herkese acik temsilci yaniti ilk yanit zamanini yazar" do
    ticket = tickets(:new_ticket)

    travel_to Time.zone.local(2026, 10, 16, 9, 30) do
      ticket.add_reply!(author: users(:one), body: "Inceliyoruz.")
    end

    assert_equal Time.zone.local(2026, 10, 16, 9, 30), ticket.reload.first_responded_at
  end

  test "ikinci yanit ilk yanit zamanini degistirmez" do
    ticket = tickets(:new_ticket)

    travel_to Time.zone.local(2026, 10, 16, 9, 30) do
      ticket.add_reply!(author: users(:one), body: "Inceliyoruz.")
    end
    travel_to Time.zone.local(2026, 10, 16, 15, 0) do
      ticket.add_reply!(author: users(:one), body: "Cozuldu.")
    end

    assert_equal Time.zone.local(2026, 10, 16, 9, 30), ticket.reload.first_responded_at
  end

  test "ic not ilk yanit sayilmaz ve durumu degistirmez" do
    ticket = tickets(:new_ticket)

    ticket.add_reply!(author: users(:one), body: "Muhasebeye soralim.", internal: true)

    assert_nil ticket.reload.first_responded_at
    assert_equal "new", ticket.status
    assert_nil ticket.assignee
  end

  test "yeni talebe yanit veren temsilci talebi ustlenir ve talep acik olur" do
    ticket = tickets(:new_ticket)

    ticket.add_reply!(author: users(:two), body: "Merhaba!")

    assert_equal users(:two), ticket.reload.assignee
    assert_equal "open", ticket.status
  end

  test "bos yanit kaydedilmez" do
    ticket = tickets(:new_ticket)

    assert_raises(ActiveRecord::RecordInvalid) do
      ticket.add_reply!(author: users(:one), body: "")
    end
    assert_equal 0, ticket.comments.count
  end
end
