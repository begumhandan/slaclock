# Ekibin is takvimi: hangi gunler, hangi saatler arasinda SLA sayaci isler?
#
# Kod yeri sorulari:
#   "SLA hafta sonunu saymasin" / "Cumartesi de calisiyoruz" -> WORK_DAYS
#   "Mesai 08:30'da baslasin" -> WORK_START / WORK_END
#   "Ekip Londra'da" -> TIME_ZONE
#   "Bayramlar sayilmasin" -> Holiday kayitlari (db/seeds.rb)
class BusinessCalendar
  TIME_ZONE = "Istanbul"
  # Date#wday: 0 = Pazar, 6 = Cumartesi
  WORK_DAYS = [ 1, 2, 3, 4, 5 ].freeze
  WORK_START = [ 9, 0 ].freeze # 09:00
  WORK_END = [ 18, 0 ].freeze # 18:00

  # Bir yuruyusun sonucu:
  #   due_at -> dakikalar bittiyse bitis ani; stop_at'e once ulasildiysa nil
  #   used   -> harcanan is dakikasi
  #   trace  -> "SLA neden bu saatte?" paneli icin adim adim kayit
  Walk = Struct.new(:due_at, :used, :trace)

  class << self
    def zone
      ActiveSupport::TimeZone[TIME_ZONE]
    end

    def working_day?(date)
      WORK_DAYS.include?(date.wday) && Holiday.name_on(date).nil?
    end

    def non_working_reason(date)
      Holiday.name_on(date) || "hafta sonu"
    end

    def window(date)
      [ zone.local(date.year, date.month, date.day, *WORK_START),
        zone.local(date.year, date.month, date.day, *WORK_END) ]
    end

    # Iki an arasindaki is dakikasi (mesai disi, hafta sonu, tatil sayilmaz).
    def business_minutes_between(from, to)
      return 0 if to <= from

      walk(from, Float::INFINITY, stop_at: to).used
    end

    # from'dan itibaren is saatlerinde ilerleyerek `minutes` is dakikasi harcar.
    # stop_at verilirse o ana gelince durur (SLA duraklatmasi icin).
    def walk(from, minutes, stop_at: nil)
      time = from.in_time_zone(zone)
      date = time.to_date
      remaining = minutes
      used = 0
      trace = []

      400.times do
        return Walk.new(nil, used, trace) if stop_at && time >= stop_at

        if working_day?(date)
          day_start, day_end = window(date)
          segment_start = [ time, day_start ].max
          segment_end = stop_at ? [ day_end, stop_at ].min : day_end

          if segment_start < segment_end
            available = ((segment_end - segment_start) / 60).floor
            if remaining <= available
              due_at = segment_start + remaining.minutes
              trace << { kind: :work, from: segment_start, to: due_at, minutes: remaining }
              return Walk.new(due_at, used + remaining, trace)
            end

            trace << { kind: :work, from: segment_start, to: segment_end, minutes: available } if available.positive?
            remaining -= available
            used += available
          end

          return Walk.new(nil, used, trace) if stop_at && stop_at < day_end && segment_end == stop_at
        else
          trace << { kind: :skip, date: date, reason: non_working_reason(date) }
        end

        date += 1
        time = zone.local(date.year, date.month, date.day)
      end

      raise "SLA hesabi 400 gunu asti"
    end
  end
end
