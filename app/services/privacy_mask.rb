# Gizlilik maskesi: metindeki kisisel verileri yer tutucularla degistirir.
# Destek ekrani (temsilci) ve LLM/ajan bu maskeli metni gorur; gercek veri yalnizca
# gerekceli erisimle (PiiAccessLog) acilir. Bkz. AGENT.md "Gizlilik kurallari".
#
# Bilerek GENEL bir yontem: duz regex kurallari + talep sahibinin adinin persona adiyla
# degistirilmesi. (Bitirme projesindeki ozgun yontemler bu herkese acik repoya konmadi.)
# Kod yeri: "IBAN da maskelensin / su format da yakalansin" -> RULES.
class PrivacyMask
  RULES = [
    [ :email, /[[:alnum:]._%+-]+@[[:alnum:].-]+\.[[:alpha:]]{2,}/, "[E-POSTA]" ],
    [ :iban, /\bTR\s?\d{2}(?:\s?\d{4}){5}\s?\d{2}\b/i, "[IBAN]" ],
    [ :card, /\b\d{4}[ -]?\d{4}[ -]?\d{4}[ -]?\d{4}\b/, "[KART_NO]" ],
    [ :national_id, /\b[1-9]\d{10}\b/, "[TC_NO]" ],
    [ :phone, /(?<!\d)(?:\+90[\s-]?|0)?\(?5\d{2}\)?[\s-]?\d{3}[\s-]?\d{2}[\s-]?\d{2}(?!\d)/, "[TELEFON]" ]
  ].freeze

  LABELS = {
    email: "e-posta", iban: "IBAN", card: "kart numarası", national_id: "TC kimlik no",
    phone: "telefon", name: "ad soyad"
  }.freeze

  Result = Struct.new(:text, :found, keyword_init: true)

  def initialize(real_name: nil, persona_name: nil)
    @name_pairs = name_pairs(real_name.to_s, persona_name.to_s)
  end

  def apply(text)
    scan(text).text
  end

  # Maskeli metni ve bulunan veri turlerini (ekranda "neler maskelendi" icin) dondurur.
  def scan(text)
    masked = text.to_s.dup
    found = []

    RULES.each do |kind, pattern, placeholder|
      next unless masked.match?(pattern)

      found << kind
      masked = masked.gsub(pattern, placeholder)
    end

    @name_pairs.each do |real, replacement|
      pattern = /(?<![[:alpha:]])#{Regexp.escape(real)}(?![[:alpha:]])/i
      next unless masked.match?(pattern)

      found << :name
      masked = masked.gsub(pattern, replacement)
    end

    Result.new(text: masked.squeeze(" "), found: found.uniq)
  end

  private
    # Gercek adin ilk parcasi persona adina, son parcasi persona soyadina, aradakiler bosa doner.
    # Uzun parcalar once denenir ki "Begum Handan" gibi tam ad tek seferde degissin.
    def name_pairs(real_name, persona_name)
      parts = real_name.split.select { |part| part.length >= 2 }
      return [] if parts.empty? || persona_name.blank?

      persona_first, persona_last = persona_name.split(" ", 2)
      pairs = [ [ parts.join(" "), persona_name ] ]
      parts.each_with_index do |part, index|
        replacement = if index.zero? then persona_first
        elsif index == parts.size - 1 then persona_last.to_s
        else ""
        end
        pairs << [ part, replacement ]
      end
      pairs.uniq(&:first).sort_by { |real, _| -real.length }
    end
end
