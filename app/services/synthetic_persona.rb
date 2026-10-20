# Sentetik profil: musterinin gercek kimligi yerine destek tarafinin gordugu, baglami koruyan profil.
# Ornek: "Ayse Kaya" / "~21–22 yaş · mühendislik öğrencisi · Samsun"
#
# - Ad: e-postadan turetilen sabit bir takma ad (ayni musteri her talepte ayni persona).
# - Yas: dogum yilindan 2 yillik aralik (dogum gunu bilinmedigi icin aralik zaten dogru cevap).
# - Meslek: cihaz ustunde (LLM'e gonderilmeden) genellestirilir; okul/sirket adi dusurulur.
# - Sehir: il duzeyinde kalir.
# Kod yeri: "Yas araligi 5 yillik olsun" -> AGE_BAND; "yeni meslek grubu" -> FIELDS.
class SyntheticPersona
  FIRST_NAMES = %w[Ayşe Elif Zeynep Deniz Ece Selin Can Emre Mert Kaan Burak Arda].freeze
  LAST_NAMES = %w[Kaya Yılmaz Şahin Çelik Aydın Arslan Doğan Koç Kurt Öztürk].freeze
  AGE_BAND = 2

  FIELDS = [
    [ /mühendis|yazılım|bilgisayar|elektrik|makine/, "mühendislik" ],
    [ /tıp|hekim|doktor|hemşire|sağlık|eczac/, "sağlık" ],
    [ /öğretmen|eğitim/, "eğitim" ],
    [ /hukuk|avukat/, "hukuk" ],
    [ /işletme|iktisat|ekonomi|finans|muhasebe|banka/, "iş ve finans" ],
    [ /mimar|tasarım|grafik/, "tasarım ve mimarlık" ]
  ].freeze
  STUDENT = /öğrenci|üniversite|fakülte|lisans|lise|sınıf/

  Persona = Struct.new(:name, :summary, keyword_init: true)

  def self.for(email:, birth_year: nil, occupation: nil, city: nil, today: Date.current)
    new(email:, birth_year:, occupation:, city:, today:).build
  end

  def initialize(email:, birth_year:, occupation:, city:, today:)
    @email, @birth_year, @occupation, @city, @today = email.to_s.downcase, birth_year, occupation, city, today
  end

  def build
    parts = [ age_band, occupation_group, @city.to_s.strip.presence ].compact
    Persona.new(name: name, summary: parts.any? ? parts.join(" · ") : "Profil bilgisi verilmedi")
  end

  private
    def name
      digest = Digest::SHA256.hexdigest(@email).to_i(16)
      "#{FIRST_NAMES[digest % FIRST_NAMES.size]} #{LAST_NAMES[(digest / FIRST_NAMES.size) % LAST_NAMES.size]}"
    end

    def age_band
      return if @birth_year.blank?

      age = @today.year - @birth_year.to_i
      return unless age.between?(10, 110)

      "~#{age - AGE_BAND + 1}–#{age} yaş"
    end

    def occupation_group
      text = @occupation.to_s.downcase(:turkic)
      return if text.blank?

      field = FIELDS.find { |pattern, _| text.match?(pattern) }&.last
      if text.match?(STUDENT)
        "#{field || "üniversite"} öğrencisi"
      else
        field ? "#{field} alanında çalışan" : "çalışan"
      end
    end
end
