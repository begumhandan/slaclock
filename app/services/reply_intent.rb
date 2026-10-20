# Musteri, bekleyen ya da cozulmus bir talebe yazdiginda niyetini LLM'e sorar:
#   resolved  -> "sorunum cozuldu, tesekkurler" (talep yeniden acilmaz)
#   new_info  -> soruya cevap, yeni bilgi ya da yeni sorun (talep acilir)
#   other     -> emin degil (talep acilir; insan baksin)
# "tesekkur" kelimesini aramak yerine cumlenin anlamina bakilir: "tesekkurler ama hala gelmedi" new_info'dur.
# LLM kapaliysa nil doner ve Ticket#add_customer_reply! eski kurali uygular (talep acilir).
class ReplyIntent
  INTENTS = %w[resolved new_info other].freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Bir destek talebine müşteriden gelen yeni mesajın niyetini sınıflandır. Kişisel veriler maskelidir.
    - "resolved": müşteri sorunun çözüldüğünü söylüyor ya da yalnızca teşekkür edip kapatıyor; yeni bir istek yok.
    - "new_info": soruya cevap veriyor, yeni bilgi ekliyor, sorunun sürdüğünü ya da yeni bir sorunu söylüyor.
    - "other": emin değilsin.
    "Teşekkürler ama hâlâ olmadı" gibi mesajlar new_info'dur.
    Yalnızca şu JSON'u döndür: {"intent": "resolved|new_info|other", "reason": "kısa gerekçe"}
  PROMPT

  def self.classify(ticket, masked_message)
    last_support = ticket.comments.where(internal: false).order(:created_at).reject(&:from_customer?).last&.body
    user = <<~TEXT
      Talep konusu: #{ticket.agent_subject}
      Talep durumu: #{ticket.status}
      Destek ekibinin son mesajı: #{last_support.presence || "(yok)"}
      Müşterinin yeni mesajı: #{masked_message}
    TEXT
    data = LlmClient.chat_json(system: SYSTEM_PROMPT, user: user)
    data.is_a?(Hash) ? data["intent"].to_s.presence_in(INTENTS) : nil
  end
end
