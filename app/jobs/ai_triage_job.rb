# Yeni talep geldiginde (web formu ya da ajan API'si) arka planda calisir:
#   1. LLM talebi okur (yalnizca maskeli metin) -> kategori, ozet, aciliyet
#   2. Aciliyet musterinin sectiginden yuksekse oncelik yukseltilir (SLA yeniden hesaplanir)
#   3. Bilgi tabanina dayanan, emin bir yanit varsa asistan yanitlar (ilk yanit sayilir)
#      yoksa talep gerekcesiyle insana devredilir (human-in-the-loop)
class AiTriageJob < ApplicationJob
  queue_as :default

  def perform(ticket_id)
    ticket = Ticket.find_by(id: ticket_id)
    return if ticket.nil? || ticket.ai_status.present? || ticket.closed?

    unless LlmClient.enabled?
      ticket.update!(ai_status: "disabled")
      return
    end

    result = TicketTriage.new(ticket).call
    if result.nil?
      ticket.update!(ai_status: "error")
      return
    end

    ticket.update!(ai_category: result.category, ai_priority: result.priority,
                   ai_summary: result.summary, ai_reason: result.reason)
    ticket.escalate_priority!(result.priority, reason: result.reason) if result.priority

    if result.auto_answer? && ticket.first_responded_at.nil?
      ticket.add_ai_reply!(body: result.answer)
      ticket.update!(ai_status: "answered")
    else
      ticket.record_handoff!(handoff_reason(result))
    end
  rescue Ticket::InvalidTransition => e
    Rails.logger.info("[AiTriageJob] ##{ticket_id}: #{e.message}")
  end

  private
    def handoff_reason(result)
      return result.handoff_reason if result.handoff_reason.present?
      return "Acil talep; asistan yanıt vermez, bir insan incelemeli" if result.priority == "urgent"

      "Bilgi tabanında dayanak yok ya da asistan emin değil"
    end
end
