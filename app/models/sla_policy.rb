# Oncelige gore ilk yanit hedefi (IS dakikasi; mesai disi, hafta sonu ve tatil sayilmaz).
# Kod yeri: "Acil talepte hedef 30 dk olsun" -> sadece bu tablo degisir.
class SlaPolicy
  FIRST_RESPONSE_MINUTES = {
    "urgent" => 60,
    "high" => 240,
    "normal" => 480,
    "low" => 1440
  }.freeze

  def self.first_response_minutes(priority)
    FIRST_RESPONSE_MINUTES.fetch(priority.to_s)
  end
end
