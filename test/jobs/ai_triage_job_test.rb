require "test_helper"

class AiTriageJobTest < ActiveJob::TestCase
  ANSWER = { "category" => "teslimat", "priority" => "normal", "summary" => "Kargo süresi soruluyor",
             "reason" => "Bilgi sorusu", "answer" => "Merhaba, siparişler 1-2 iş gününde kargoya verilir.",
             "sources" => [ "kargo-suresi" ], "confidence" => 0.9, "handoff_reason" => "" }.freeze

  def create_ticket(priority: "normal")
    travel_to(Time.zone.local(2026, 10, 20, 10, 0)) do
      Ticket.create!(subject: "Siparişim ne zaman gelir?", requester_email: "begum@example.com",
                     requester_name: "Begüm Demir", priority: priority,
                     body: "Ben Begüm Demir, telefonum 0532 123 45 67, TC 12345678901, mail begum@example.com")
    end
  end

  test "LLM'e hicbir kisisel veri gitmez" do
    llm = LlmClient.adapter = FakeLlm.new(ANSWER)
    ticket = create_ticket

    AiTriageJob.perform_now(ticket.id)

    prompts = llm.all_prompts
    assert_no_match(/Begüm|Demir|0532|12345678901|begum@example\.com/, prompts)
    assert_includes prompts, "[TELEFON]"
    assert_includes prompts, ticket.persona_name
  end

  test "bilgi tabanina dayanan emin yanit: asistan yanitlar, ilk yanit sayilir, musteri beklenir" do
    LlmClient.adapter = FakeLlm.new(ANSWER)
    ticket = create_ticket

    travel_to(Time.zone.local(2026, 10, 20, 10, 5)) { AiTriageJob.perform_now(ticket.id) }

    ticket.reload
    assert_equal "answered", ticket.ai_status
    assert_equal "pending", ticket.status
    assert_equal Time.zone.local(2026, 10, 20, 10, 5), ticket.first_responded_at
    reply = ticket.comments.find_by!(ai_generated: true, internal: false)
    assert_equal ANSWER["answer"], reply.body
    assert_not reply.from_customer?
  end

  test "kaynak gostermeyen yanit yayinlanmaz, insana devredilir (halusinasyon korumasi)" do
    LlmClient.adapter = FakeLlm.new(ANSWER.merge("sources" => [ "uydurma-madde" ]))
    ticket = create_ticket

    AiTriageJob.perform_now(ticket.id)

    ticket.reload
    assert_equal "handed_off", ticket.ai_status
    assert_equal "new", ticket.status
    assert_nil ticket.first_responded_at
    assert ticket.comments.where(ai_generated: true, internal: false).none?
    assert ticket.comments.find_by(ai_generated: true, internal: true).body.start_with?("İnsana devredildi")
  end

  test "emin olmayan asistan insana devreder" do
    LlmClient.adapter = FakeLlm.new(ANSWER.merge("confidence" => 0.4, "handoff_reason" => "Müşteri öfkeli"))
    ticket = create_ticket

    AiTriageJob.perform_now(ticket.id)

    assert_equal "handed_off", ticket.reload.ai_status
    assert_match "Müşteri öfkeli", ticket.comments.find_by(internal: true).body
  end

  test "LLM daha acil derse oncelik yukselir ve SLA yeniden hesaplanir; asla dusurulmez" do
    LlmClient.adapter = FakeLlm.new(ANSWER.merge("priority" => "urgent", "answer" => "", "sources" => []))
    ticket = create_ticket(priority: "low")
    assert_equal Time.zone.local(2026, 10, 22, 16, 0), ticket.first_response_due_at # 24 is saati: Sal 8 + Car 9 + Per 7

    travel_to(Time.zone.local(2026, 10, 20, 10, 1)) { AiTriageJob.perform_now(ticket.id) }

    ticket.reload
    assert_equal "urgent", ticket.priority
    assert_equal Time.zone.local(2026, 10, 20, 11, 0), ticket.first_response_due_at # 1 is saati
    assert ticket.comments.exists?(internal: true, ai_generated: true, body: "Öncelik yükseltildi (low → urgent): Bilgi sorusu")

    other = create_ticket(priority: "high")
    LlmClient.adapter = FakeLlm.new(ANSWER.merge("priority" => "low"))
    AiTriageJob.perform_now(other.id)
    assert_equal "high", other.reload.priority
  end

  test "anahtar yoksa yapay zeka kapali kalir, talep klasik akista" do
    ticket = create_ticket

    AiTriageJob.perform_now(ticket.id)

    assert_equal "disabled", ticket.reload.ai_status
    assert_equal "new", ticket.status
  end

  test "LLM hata verirse talep bozulmaz" do
    LlmClient.adapter = FakeLlm.new(nil)
    ticket = create_ticket

    AiTriageJob.perform_now(ticket.id)

    assert_equal "error", ticket.reload.ai_status
  end
end
