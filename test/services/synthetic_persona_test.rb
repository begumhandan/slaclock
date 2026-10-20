require "test_helper"

class SyntheticPersonaTest < ActiveSupport::TestCase
  test "baglami koruyan ama kimligi gizleyen profil uretir" do
    persona = SyntheticPersona.for(email: "begum@example.com", birth_year: 2004,
                                   occupation: "Samsun Üniversitesi Yazılım Mühendisliği 4. sınıf", city: "Samsun",
                                   today: Date.new(2026, 10, 20))

    assert_equal "~21–22 yaş · mühendislik öğrencisi · Samsun", persona.summary
    assert_no_match(/Üniversitesi|Begüm/i, "#{persona.name} #{persona.summary}")
  end

  test "ayni musteri her zaman ayni takma adi alir" do
    first = SyntheticPersona.for(email: "Ayse@Example.com").name
    assert_equal first, SyntheticPersona.for(email: "ayse@example.com").name
    assert_match(/\A\S+ \S+\z/, first)
  end

  test "bilgi verilmediyse bunu soyler" do
    assert_equal "Profil bilgisi verilmedi", SyntheticPersona.for(email: "a@example.com").summary
  end

  test "meslek genellestirilir" do
    assert_equal "sağlık alanında çalışan", SyntheticPersona.for(email: "a@b.co", occupation: "Hemşire").summary
    assert_equal "çalışan", SyntheticPersona.for(email: "a@b.co", occupation: "Kargo şoförü").summary
  end
end
