module SlaHelper
  DAYS = %w[Pazar Pazartesi Salı Çarşamba Perşembe Cuma Cumartesi].freeze
  MONTHS = %w[_ Ocak Şubat Mart Nisan Mayıs Haziran Temmuz Ağustos Eylül Ekim Kasım Aralık].freeze

  def tr_date(date)
    "#{date.day} #{MONTHS[date.month]} #{DAYS[date.wday]}"
  end

  def tr_clock(time)
    time.in_time_zone(BusinessCalendar.zone).strftime("%H:%M")
  end

  def tr_time(time)
    time = time.in_time_zone(BusinessCalendar.zone)
    "#{tr_date(time.to_date)} #{tr_clock(time)}"
  end

  def duration_text(minutes)
    hours, mins = minutes.to_i.divmod(60)
    [ (hours.positive? ? "#{hours} sa" : nil), (mins.positive? || hours.zero? ? "#{mins} dk" : nil) ].compact.join(" ")
  end

  # Kalan surenin durumu: :running, :soon (son %25), :paused, :breached, :met
  def sla_info(ticket, now: Time.current)
    target = SlaPolicy.first_response_minutes(ticket.priority)
    used_pct = ->(remaining) { (100 - (remaining.to_f / target * 100)).clamp(0, 100).round }

    case ticket.sla_state(now)
    when :met
      { state: :met, pct: 100, text: ticket.first_responded_at ? "Zamanında yanıtlandı" : "Yanıt gerekmeden çözüldü" }
    when :paused
      remaining = SlaClock.new(ticket, now: now).compute.remaining_minutes
      { state: :paused, pct: used_pct.call(remaining), text: "Durdu, #{duration_text(remaining)} kaldı" }
    when :breached
      if ticket.first_responded_at
        { state: :breached, pct: 100, text: "Geç yanıtlandı" }
      else
        # Cozulmus/kapanmis talepte gecikme cozulme aninda donar; sonsuza kadar buyumez.
        finished_at = ticket.status.in?(%w[solved closed]) ? (ticket.solved_at || now) : now
        late = BusinessCalendar.business_minutes_between(ticket.first_response_due_at, finished_at)
        text = late.positive? ? "#{duration_text(late)} gecikti" : "Süre doldu"
        text = "Yanıtlanmadan çözüldü, #{text}" if finished_at != now
        { state: :breached, pct: 100, text: text }
      end
    else
      return { state: :none, pct: 0, text: "—" } unless ticket.first_response_due_at

      remaining = BusinessCalendar.business_minutes_between(now, ticket.first_response_due_at)
      state = remaining <= target * 0.25 ? :soon : :running
      { state: state, pct: used_pct.call(remaining), text: "#{duration_text(remaining)} kaldı" }
    end
  end

  def sla_meter(ticket, info: sla_info(ticket))
    tag.div(class: "meter meter-#{info[:state]}") do
      tag.div(class: "meter-track") { tag.div(class: "meter-fill", style: "width: #{info[:pct]}%") } +
        tag.div(info[:text], class: "meter-text num")
    end
  end

  # Zaman cizelgesindeki her adim: [ne zaman, ne oldu]
  def sla_step_parts(step)
    case step[:kind]
    when :start
      [ tr_time(step[:at]), "Talep geldi. Hedef: #{duration_text(step[:minutes])} iş süresi." ]
    when :work
      [ "#{tr_date(step[:from].to_date)}, #{tr_clock(step[:from])}–#{tr_clock(step[:to])}", "#{duration_text(step[:minutes])} sayıldı" ]
    when :skip
      [ tr_date(step[:date]), "Sayılmadı: #{step[:reason]}" ]
    when :pause
      if step[:to]
        [ "#{tr_time(step[:from])} – #{tr_clock(step[:to])}", "3. taraf beklendi, sayaç durdu" ]
      else
        [ "#{tr_time(step[:from])}'dan beri", "3. taraf bekleniyor, sayaç duruyor. Kalan: #{duration_text(step[:remaining])}" ]
      end
    when :due
      [ tr_time(step[:at]), "İlk yanıt için son an" ]
    end
  end

  # Eski metin bicimi (testler ve basit kullanim icin)
  def sla_step_text(step)
    sla_step_parts(step).join(": ")
  end
end
