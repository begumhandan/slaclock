# Testlerde gercek LLM yerine kullanilir: hazir JSON yanitlari sirayla doner ve
# kendisine gonderilen her istemi kaydeder (LLM'e ham kisisel veri gitmedigini dogrulamak icin).
class FakeLlm
  attr_reader :calls

  def initialize(*responses, enabled: true)
    @responses = responses
    @enabled = enabled
    @calls = []
  end

  def enabled?
    @enabled
  end

  def chat_json(system:, user:)
    @calls << { system: system, user: user }
    @responses.length > 1 ? @responses.shift : @responses.first
  end

  def all_prompts
    @calls.map { |call| "#{call[:system]}\n#{call[:user]}" }.join("\n")
  end
end
