# Temsilci hesabi. Canlida e-posta ve sifre Render ortam degiskenlerinden
# (ADMIN_EMAIL, ADMIN_PASSWORD) gelir. Idempotent: hesap zaten varsa dokunmaz.
email = ENV.fetch("ADMIN_EMAIL", Rails.env.production? ? nil : "temsilci@slaclock.test")
password = ENV.fetch("ADMIN_PASSWORD", Rails.env.production? ? nil : "slaclock123")

if email.present? && password.present?
  User.find_or_create_by!(email_address: email) do |user|
    user.password = password
  end
end
