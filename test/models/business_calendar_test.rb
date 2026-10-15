require "test_helper"

class BusinessCalendarTest < ActiveSupport::TestCase
  test "hafta ici calisma gunu, hafta sonu degil" do
    assert BusinessCalendar.working_day?(Date.new(2026, 10, 16)) # Cuma
    assert_not BusinessCalendar.working_day?(Date.new(2026, 10, 17)) # Cumartesi
    assert_not BusinessCalendar.working_day?(Date.new(2026, 10, 18)) # Pazar
  end

  test "resmi tatil calisma gunu degil" do
    assert_not BusinessCalendar.working_day?(Date.new(2026, 10, 29))
    assert_equal "Cumhuriyet Bayramı", BusinessCalendar.non_working_reason(Date.new(2026, 10, 29))
  end

  test "mesai disinda baslayan sure 09:00'da baslar" do
    walk = BusinessCalendar.walk(Time.zone.local(2026, 10, 19, 8, 0), 60) # Pazartesi 08:00

    assert_equal Time.zone.local(2026, 10, 19, 10, 0), walk.due_at
  end
end
