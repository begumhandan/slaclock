require "test_helper"

# Musterinin "tesekkurler" yaniti talebi yeniden acsin mi? Karari LLM verir (anahtar kelime yok).
class ReplyIntentTest < ActiveSupport::TestCase
  setup do
    @ticket = Ticket.create!(subject: "Kargo", requester_email: "a@example.com", requester_name: "Ayla Yıldız",
                             body: "Siparişim nerede?")
    @ticket.add_reply!(author: users(:one), body: "Kargonuz yarın teslim edilecek.")
  end

  test "cozulmus talebe 'tesekkurler, cozuldu' yazilirsa talep kapali kalir" do
    LlmClient.adapter = FakeLlm.new({ "intent" => "resolved", "reason" => "teşekkür" })
    @ticket.transition_to!(:solved)

    comment = @ticket.add_customer_reply!(body: "Çok teşekkürler, elime ulaştı!")

    assert_equal "solved", @ticket.reload.status
    assert_equal "resolved", comment.intent
  end

  test "musteri bekleniyorken 'cozuldu' yazilirsa talep cozulur" do
    LlmClient.adapter = FakeLlm.new({ "intent" => "resolved" })
    @ticket.transition_to!(:pending)

    @ticket.add_customer_reply!(body: "Tamamdır, sorun kalmadı.")

    assert_equal "solved", @ticket.reload.status
  end

  test "'tesekkurler ama hala gelmedi' yeni bilgidir, talep yeniden acilir" do
    LlmClient.adapter = FakeLlm.new({ "intent" => "new_info" })
    @ticket.transition_to!(:solved)

    @ticket.add_customer_reply!(body: "Teşekkürler ama hâlâ gelmedi.")

    assert_equal "open", @ticket.reload.status
  end

  test "LLM'e musterinin gercek adi gitmez" do
    llm = LlmClient.adapter = FakeLlm.new({ "intent" => "new_info" })
    @ticket.transition_to!(:solved)

    @ticket.add_customer_reply!(body: "Ben Ayla Yıldız, numaram 0532 123 45 67")

    assert_no_match(/Ayla|Yıldız|0532/, llm.all_prompts)
  end

  test "yapay zeka kapaliysa eski kural: talep yeniden acilir" do
    @ticket.transition_to!(:solved)

    @ticket.add_customer_reply!(body: "Teşekkürler")

    assert_equal "open", @ticket.reload.status
  end
end
