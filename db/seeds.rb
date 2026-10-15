# Temsilci hesaplari. Canlida e-posta ve sifre Render ortam degiskenlerinden gelir:
# ADMIN_EMAIL / ADMIN_PASSWORD (asil hesap), DEMO_EMAIL / DEMO_PASSWORD (hocaya verilen demo hesap, istege bagli).
# Idempotent: hesap zaten varsa dokunmaz.
[
  [ ENV.fetch("ADMIN_EMAIL", Rails.env.production? ? nil : "temsilci@slaclock.test"),
    ENV.fetch("ADMIN_PASSWORD", Rails.env.production? ? nil : "slaclock123") ],
  [ ENV["DEMO_EMAIL"], ENV["DEMO_PASSWORD"] ]
].each do |email, password|
  next if email.blank? || password.blank?

  User.find_or_create_by!(email_address: email) do |user|
    user.password = password
  end
end

# Resmi tatiller (sabit tarihli olanlar). SLA sayaci bu gunlerde islemez.
# Dini bayramlar ve yarim gunler henuz yok (README: Yapamadiklarim).
{
  "2026-10-29" => "Cumhuriyet Bayramı",
  "2027-01-01" => "Yılbaşı",
  "2027-04-23" => "Ulusal Egemenlik ve Çocuk Bayramı",
  "2027-05-01" => "Emek ve Dayanışma Günü",
  "2027-05-19" => "Atatürk'ü Anma, Gençlik ve Spor Bayramı",
  "2027-07-15" => "Demokrasi ve Milli Birlik Günü",
  "2027-08-30" => "Zafer Bayramı",
  "2027-10-29" => "Cumhuriyet Bayramı"
}.each do |date, name|
  Holiday.find_or_create_by!(date: Date.parse(date)) { |holiday| holiday.name = name }
end
