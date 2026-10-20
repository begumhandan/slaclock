require "test_helper"

# Agent-first: musteri tarafindaki bir ajan JSON API ile talep acar, izler, yanit yazar.
class ApiTicketsTest < ActionDispatch::IntegrationTest
  setup do
    @old_token = ENV["AGENT_API_TOKEN"]
    ENV["AGENT_API_TOKEN"] = "test-ajan-anahtari"
    @auth = { "Authorization" => "Bearer test-ajan-anahtari" }
  end

  teardown { ENV["AGENT_API_TOKEN"] = @old_token }

  test "anahtarsiz istek reddedilir" do
    post api_v1_tickets_url, params: { subject: "x", requester_email: "a@example.com" }, as: :json
    assert_response :unauthorized
  end

  test "sunucuda anahtar tanimli degilse API kapali" do
    ENV["AGENT_API_TOKEN"] = nil
    post api_v1_tickets_url, params: { subject: "x" }, headers: @auth, as: :json
    assert_response :service_unavailable
  end

  test "ajan talep acar; ayni is kurallari ve yapay zeka kuyrugu calisir" do
    assert_enqueued_with(job: AiTriageJob) do
      post api_v1_tickets_url, headers: @auth, as: :json,
           params: { subject: "Siparişim nerede?", requester_email: "ajan@example.com", priority: "high",
                     body: "Telefon 0532 123 45 67", requester_name: "Ayla Yıldız", birth_year: 2000 }
    end

    assert_response :created
    json = response.parsed_body
    ticket = Ticket.find(json["id"])
    assert_equal "api", ticket.source
    assert_equal "new", json["status"]
    assert_not_nil json["first_response_due_at"]
    assert_includes json["customer_url"], ticket.access_token
    assert_no_match(/0532/, ticket.agent_body)
  end

  test "eksik alanla talep acilmaz" do
    post api_v1_tickets_url, headers: @auth, as: :json, params: { subject: "" }
    assert_response :unprocessable_content
  end

  test "ajan durumu ve mesajlari okur; ic notlari goremez" do
    get api_v1_ticket_url(tickets(:open_ticket).access_token), headers: @auth, as: :json

    assert_response :success
    bodies = response.parsed_body["messages"].map { |m| m["body"] }
    assert_includes bodies, comments(:open_ticket_reply).body
    assert_not_includes bodies, comments(:open_ticket_internal_note).body
  end

  test "ajan musteri adina yanit yazar" do
    ticket = tickets(:open_ticket)
    ticket.transition_to!(:pending)

    post api_v1_ticket_replies_url(ticket.access_token), headers: @auth, as: :json, params: { body: "Ek bilgi" }

    assert_response :created
    assert_equal "open", response.parsed_body["status"]
  end

  test "yanlis anahtarli talep bulunamaz" do
    get api_v1_ticket_url("yok"), headers: @auth, as: :json
    assert_response :not_found
  end
end
