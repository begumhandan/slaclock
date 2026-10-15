module SlaHelper
  DAYS = %w[Pazar Pazartesi Salı Çarşamba Perşembe Cuma Cumartesi].freeze
  MONTHS = %w[_ Ocak Şubat Mart Nisan Mayıs Haziran Temmuz Ağustos Eylül Ekim Kasım Aralık].freeze

  def tr_date(date)
    "#{date.day} #{MONTHS[date.month]} #{DAYS[date.wday]}"
  end

  def tr_time(time)
    time = time.in_time_zone(BusinessCalendar.zone)
    "#{tr_date(time.to_date)} #{time.strftime('%H:%M')}"
  end

  def duration_text(minutes)
    hours, mins = minutes.divmod(60)
    [ (hours.positive? ? "#{hours} sa" : nil), (mins.positive? || hours.zero? ? "#{mins} dk" : nil) ].compact.join(" ")
  end

  def sla_badge(ticket)
    case ticket.sla_state
    when :met then "✅ Zamanında yanıtlandı"
    when :breached then "🔴 SLA ihlali"
    when :paused then "⏸ Durdu (3. taraf bekleniyor)"
    else ticket.first_response_due_at ? "⏱ #{tr_time(ticket.first_response_due_at)}" : "—"
    end
  end

  def sla_step_text(step)
    case step[:kind]
    when :start
      "Talep #{tr_time(step[:at])}'da geldi. Hedef: #{duration_text(step[:minutes])} iş süresi."
    when :work
      "#{tr_date(step[:from].to_date)} #{step[:from].strftime('%H:%M')}–#{step[:to].strftime('%H:%M')}: #{duration_text(step[:minutes])} sayıldı."
    when :skip
      "#{tr_date(step[:date])}: sayılmadı (#{step[:reason]})."
    when :pause
      if step[:to]
        "⏸ #{tr_time(step[:from])} – #{tr_time(step[:to])}: 3. taraf beklendi, sayaç durdu."
      else
        "⏸ #{tr_time(step[:from])}'dan beri 3. taraf bekleniyor; sayaç durdu. Kalan: #{duration_text(step[:remaining])}."
      end
    when :due
      "➡ İlk yanıt son tarihi: #{tr_time(step[:at])}."
    end
  end
end
