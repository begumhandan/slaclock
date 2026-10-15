require "net/http"
require "json"

# Render ucretsiz planinda SMTP portlari (25, 465, 587) kapali. Bu yuzden e-postalar
# Resend'in HTTPS API'si uzerinden gonderilir. Anahtar: RESEND_API_KEY ortam degiskeni.
class ResendDelivery
  ENDPOINT = URI("https://api.resend.com/emails")

  attr_reader :settings

  def initialize(settings)
    @settings = settings
  end

  def deliver!(mail)
    request = Net::HTTP::Post.new(ENDPOINT)
    request["Authorization"] = "Bearer #{settings.fetch(:api_key)}"
    request["Content-Type"] = "application/json"
    request.body = payload(mail).to_json

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true, open_timeout: 5, read_timeout: 10) do |http|
      http.request(request)
    end
    raise "Resend e-postayi kabul etmedi (#{response.code}): #{response.body}" unless response.is_a?(Net::HTTPSuccess)

    response
  end

  def payload(mail)
    {
      from: mail[:from].to_s,
      to: mail.to,
      subject: mail.subject,
      # Message#decoded metni karakter kumesine (UTF-8) cevirir; Body#decoded ham bayt dondurur.
      html: (mail.html_part || mail).decoded,
      text: mail.text_part&.decoded
    }.compact
  end
end

ActiveSupport.on_load(:action_mailer) do
  add_delivery_method :resend, ResendDelivery, api_key: ENV["RESEND_API_KEY"]
end
