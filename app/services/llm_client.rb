require "net/http"

# LLM istemcisi (Groq, OpenAI uyumlu API). Anahtar yoksa kapali kalir ve nil doner;
# uygulama o zaman yapay zekasiz eski kurallarla calisir.
#
# GIZLILIK KURALI: Bu istemciye yalnizca MASKELI metin verilir (Ticket#agent_subject,
# #agent_body, PrivacyMask#apply). Bunu test/jobs/ai_triage_job_test.rb dogruluyor.
#
# Testlerde gercek API cagrilmaz: LlmClient.adapter = FakeLlm.new(...) (test/test_helpers).
class LlmClient
  ENDPOINT = URI("https://api.groq.com/openai/v1/chat/completions")
  DEFAULT_MODEL = "llama-3.3-70b-versatile"
  TIMEOUT = 15

  class << self
    attr_writer :adapter

    def adapter
      @adapter ||= new
    end

    def enabled?
      adapter.enabled?
    end

    # JSON nesnesi (Hash) dondurur; kapaliysa ya da hata olursa nil.
    def chat_json(system:, user:)
      adapter.chat_json(system: system, user: user)
    end
  end

  def enabled?
    ENV["GROQ_API_KEY"].present?
  end

  def chat_json(system:, user:)
    return nil unless enabled?

    request = Net::HTTP::Post.new(ENDPOINT, "Content-Type" => "application/json",
                                            "Authorization" => "Bearer #{ENV.fetch("GROQ_API_KEY")}")
    request.body = {
      model: ENV.fetch("GROQ_MODEL", DEFAULT_MODEL),
      temperature: 0.2,
      response_format: { type: "json_object" },
      messages: [ { role: "system", content: system }, { role: "user", content: user } ]
    }.to_json

    response = Net::HTTP.start(ENDPOINT.host, ENDPOINT.port, use_ssl: true,
                               open_timeout: 5, read_timeout: TIMEOUT) { |http| http.request(request) }
    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.warn("[LlmClient] HTTP #{response.code}: #{response.body.to_s.first(300)}")
      return nil
    end

    content = JSON.parse(response.body).dig("choices", 0, "message", "content")
    JSON.parse(content.to_s)
  rescue StandardError => e
    Rails.logger.warn("[LlmClient] #{e.class}: #{e.message}")
    nil
  end
end
