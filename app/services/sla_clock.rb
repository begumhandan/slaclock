# Bir talebin ilk yanit SLA'sini hesaplar: talep geldigi andan itibaren is takvimine gore
# ilerler, on_hold araliklarinda (SlaPause) durur. Tek dogru kaynak budur;
# hem tickets.first_response_due_at hem de "SLA neden bu saatte?" paneli buradan beslenir.
class SlaClock
  Result = Struct.new(:due_at, :paused, :remaining_minutes, :steps, keyword_init: true)

  def initialize(ticket, now: Time.current)
    @ticket = ticket
    @now = now
  end

  def target_minutes
    SlaPolicy.first_response_minutes(@ticket.priority)
  end

  def compute
    start = @ticket.created_at || @now
    remaining = target_minutes
    cursor = start
    steps = [ { kind: :start, at: start, minutes: remaining } ]

    pauses.each do |pause|
      walk = BusinessCalendar.walk(cursor, remaining, stop_at: pause.started_at)
      steps.concat(walk.trace)
      return finished(walk.due_at, steps) if walk.due_at

      remaining -= walk.used
      if pause.ended_at
        steps << { kind: :pause, from: pause.started_at, to: pause.ended_at }
        cursor = pause.ended_at
      else
        steps << { kind: :pause, from: pause.started_at, to: nil, remaining: remaining }
        return Result.new(due_at: nil, paused: true, remaining_minutes: remaining, steps: steps)
      end
    end

    walk = BusinessCalendar.walk(cursor, remaining)
    finished(walk.due_at, steps.concat(walk.trace))
  end

  private
    def pauses
      return [] if @ticket.new_record?

      pauses = @ticket.sla_pauses.chronological
      # Ilk yanittan sonra baslayan beklemeler ilk yanit SLA'sini etkilemez.
      pauses = pauses.where(started_at: ...@ticket.first_responded_at) if @ticket.first_responded_at
      pauses.to_a
    end

    def finished(due_at, steps)
      steps << { kind: :due, at: due_at }
      Result.new(due_at: due_at, paused: false, remaining_minutes: 0, steps: steps)
    end
end
