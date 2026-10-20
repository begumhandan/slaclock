module TicketsHelper
  STATUS_LABELS = Ticket::STATUS_LABELS

  PRIORITY_LABELS = {
    "low" => "Düşük",
    "normal" => "Normal",
    "high" => "Yüksek",
    "urgent" => "Acil"
  }.freeze

  def status_label(status) = STATUS_LABELS.fetch(status.to_s, status.to_s)
  def priority_label(priority) = PRIORITY_LABELS.fetch(priority.to_s, priority.to_s)

  def status_chip(status)
    tag.span(status_label(status), class: "chip chip-status-#{status}")
  end

  def priority_tag(priority)
    tag.span(priority_label(priority), class: "prio prio-#{priority}")
  end

  def ai_badge(ticket)
    case ticket.ai_status
    when "answered" then tag.span("🤖 AI yanıtladı", class: "ai-badge ai-answered")
    when "handed_off" then tag.span("🙋 İnsana devredildi", class: "ai-badge ai-handed_off")
    end
  end

  def initials(email)
    email.to_s.split("@").first.to_s.first(2).upcase
  end
end
