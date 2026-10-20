# Talebi LLM'e okutur: kategori, aciliyet, ozet ve "asistan yanitlayabilir mi?" kararlari.
# Anahtar kelime eslestirmesi YOK; kararlar LLM'den gelir, kodda yalnizca guvenlik kontrolleri var:
#   - LLM'e yalnizca maskeli metin gider (Ticket#agent_subject / #agent_body).
#   - Asistan yalnizca bilgi tabanindaki (config/knowledge_base.yml) bir maddeye dayanarak yanit yazabilir;
#     kaynak gostermezse ya da emin degilse talep insana devredilir (halusinasyonu azaltmak icin).
#   - LLM'in KENDI karari "insan gerekli" ya da "acil" ise asistan yanit yazsa bile yayinlanmaz.
#     (Canlida ilk denemede model, hukuki tehdit iceren cift cekim sikayetine bilgi tabanindan
#     yanlis bir madde uydurup yanit verdi; bu kural o yuzden eklendi. Bkz. CHALLENGE_LOG.)
# Kod yeri: "Asistan daha cesur/temkinli olsun" -> MIN_CONFIDENCE.
class TicketTriage
  CATEGORIES = %w[teslimat iade odeme hesap fatura teknik sikayet diger].freeze
  MIN_CONFIDENCE = 0.75

  Result = Struct.new(:category, :priority, :summary, :reason, :answer, :sources,
                      :confidence, :needs_human, :handoff_reason, keyword_init: true) do
    def auto_answer?
      answer.present? && sources.any? && confidence >= MIN_CONFIDENCE && !needs_human && priority != "urgent"
    end
  end

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Sen bir e-ticaret şirketinin destek asistanısın. Talepler sana KİŞİSEL VERİLERİ MASKELENMİŞ olarak gelir
    ([E-POSTA], [TELEFON], [TC_NO] gibi yer tutucular ve sahte bir müşteri adı). Gerçek veriyi tahmin etmeye çalışma.

    Görevlerin:
    1. Talebi bir kategoriye ayır: #{CATEGORIES.join(", ")}.
    2. Aciliyeti değerlendir: low, normal, high, urgent. Para kaybı, güvenlik, hesabın ele geçirilmesi,
       sağlık riski gibi durumlar urgent; işini yapamamak high; bilgi sorusu normal ya da low.
    3. Tek cümlelik Türkçe özet yaz.
    4. Talebi YALNIZCA aşağıdaki bilgi tabanı maddelerine dayanarak tam olarak yanıtlayabiliyorsan,
       müşteriye nazik, kısa bir Türkçe yanıt yaz ve dayandığın madde id'lerini "sources" listesine koy.
       Bilgi tabanında olmayan hiçbir bilgi, süre, tutar ya da söz ekleme.
       Şikâyet, öfke, hukuki tehdit, para kaybı, kişiye özel inceleme gerektiren durum ya da emin olmadığın her durumda
       "needs_human" true olsun, "answer" boş kalsın ve "handoff_reason" içinde nedenini yaz.
       Bilgi tabanındaki bir maddeyi müşterinin durumuna uymuyorsa zorlama.

    Yalnızca şu JSON'u döndür:
    {"category": "...", "priority": "low|normal|high|urgent", "summary": "...", "reason": "aciliyet gerekçesi",
     "answer": "... ya da boş", "sources": ["madde-id"], "confidence": 0.0-1.0, "needs_human": true|false,
     "handoff_reason": "... ya da boş"}
  PROMPT

  def self.knowledge_base
    @knowledge_base ||= YAML.load_file(Rails.root.join("config/knowledge_base.yml"))
  end

  def initialize(ticket)
    @ticket = ticket
  end

  def user_prompt
    articles = self.class.knowledge_base.map { |a| "[#{a["id"]}] #{a["title"]}: #{a["content"]}" }.join("\n")
    <<~TEXT
      BİLGİ TABANI:
      #{articles}

      TALEP:
      Müşteri profili (sentetik): #{@ticket.persona_name}, #{@ticket.persona_summary}
      Müşterinin seçtiği öncelik: #{@ticket.priority}
      Konu: #{@ticket.agent_subject}
      Mesaj: #{@ticket.agent_body.presence || "(boş)"}
    TEXT
  end

  def call
    data = LlmClient.chat_json(system: SYSTEM_PROMPT, user: user_prompt)
    return nil unless data.is_a?(Hash)

    known_ids = self.class.knowledge_base.map { |a| a["id"] }
    Result.new(
      category: data["category"].to_s.presence_in(CATEGORIES) || "diger",
      priority: data["priority"].to_s.presence_in(Ticket.priorities.keys),
      summary: data["summary"].to_s.first(300),
      reason: data["reason"].to_s.first(300),
      answer: data["answer"].to_s.strip.first(2000),
      sources: Array(data["sources"]).map(&:to_s) & known_ids,
      confidence: data["confidence"].to_f.clamp(0.0, 1.0),
      needs_human: data["needs_human"] == true || data["needs_human"].to_s == "true",
      handoff_reason: data["handoff_reason"].to_s.first(300)
    )
  end
end
