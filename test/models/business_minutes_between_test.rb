require "test_helper"

class BusinessMinutesBetweenTest < ActiveSupport::TestCase
  test "ayni gun icinde dakika farki" do
    minutes = BusinessCalendar.business_minutes_between(Time.zone.local(2026, 10, 19, 10, 0), Time.zone.local(2026, 10, 19, 12, 30))

    assert_equal 150, minutes
  end

  test "hafta sonu ve mesai disi sayilmaz" do
    # Cuma 17:00 -> Pazartesi 10:00 = Cuma 1 sa + Pazartesi 1 sa
    minutes = BusinessCalendar.business_minutes_between(Time.zone.local(2026, 10, 16, 17, 0), Time.zone.local(2026, 10, 19, 10, 0))

    assert_equal 120, minutes
  end

  test "geriye dogru sure sifirdir" do
    assert_equal 0, BusinessCalendar.business_minutes_between(Time.zone.local(2026, 10, 19, 12, 0), Time.zone.local(2026, 10, 19, 10, 0))
  end
end
