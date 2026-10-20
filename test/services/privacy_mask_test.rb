require "test_helper"

class PrivacyMaskTest < ActiveSupport::TestCase
  setup { @mask = PrivacyMask.new(real_name: "Begüm Handan Demir", persona_name: "Zeynep Kaya") }

  test "e-posta, telefon, TC no, IBAN ve kart numarasi yer tutucuyla degisir" do
    text = "Mail begum.demir@gmail.com, tel 0532 123 45 67, +90 555 111 2233, TC 12345678901, " \
           "IBAN TR33 0006 1005 1978 6457 8413 26, kart 4111 1111 1111 1111"
    result = @mask.scan(text)

    assert_equal "Mail [E-POSTA], tel [TELEFON], [TELEFON], TC [TC_NO], IBAN [IBAN], kart [KART_NO]", result.text
    assert_equal %i[email iban card national_id phone].sort, result.found.sort
  end

  test "gercek ad persona adiyla degisir" do
    assert_equal "Merhaba ben Zeynep Kaya. Zeynep'in siparisi.",
                 @mask.apply("Merhaba ben Begüm Handan Demir. Begüm'in siparisi.")
  end

  test "siparis numarasi gibi kisa sayilar maskelenmez" do
    assert_equal "Sipariş no 123456, tutar 2450 TL", @mask.apply("Sipariş no 123456, tutar 2450 TL")
  end

  test "bos metin hata vermez" do
    assert_equal "", @mask.apply(nil)
  end
end
