require "test_helper"

# Kisisel hedef: temsilci gercek veriyi gormez; gerekceyle acar ve her acilis kayda gecer.
class PrivacyScreenTest < ActionDispatch::IntegrationTest
  setup do
    @ticket = Ticket.create!(subject: "Begüm Demir: iade", requester_email: "begum@example.com",
                             requester_name: "Begüm Demir", birth_year: 2004,
                             occupation: "Yazılım mühendisliği öğrencisi", city: "Samsun",
                             body: "Telefonum 0532 123 45 67, TC 12345678901.")
    sign_in_as(users(:one))
  end

  test "talep sayfasinda ve listede gercek kisisel veri yok, sentetik profil var" do
    get ticket_url(@ticket)
    assert_response :success
    assert_no_match(/begum@example\.com|Begüm|0532 123|12345678901/, response.body)
    assert_includes response.body, @ticket.persona_name
    assert_includes response.body, "mühendislik öğrencisi"

    get tickets_url
    assert_no_match(/begum@example\.com|Begüm/, response.body)
  end

  test "gerekcesiz gercek veri acilmaz" do
    assert_no_difference("PiiAccessLog.count") { post reveal_ticket_url(@ticket), params: { reason: "" } }
    assert_redirected_to ticket_url(@ticket)
  end

  test "gerekceyle acilir ve kayda gecer" do
    assert_difference("PiiAccessLog.count", 1) do
      post reveal_ticket_url(@ticket), params: { reason: "Kargo firmasına telefon iletilecek" }
    end

    assert_response :success
    assert_includes response.body, "begum@example.com"
    assert_includes response.body, "0532 123 45 67"
    log = PiiAccessLog.last
    assert_equal users(:one), log.user
    assert_equal "Kargo firmasına telefon iletilecek", log.reason

    get ticket_url(@ticket)
    assert_includes response.body, "Kargo firmasına telefon iletilecek"
    assert_no_match(/0532 123/, response.body)
  end

  test "musteri kendi sayfasinda kendi verisini gorur" do
    sign_out
    get customer_ticket_url(@ticket.access_token)
    assert_includes response.body, "0532 123 45 67"
  end

  test "formdan acilan talep yapay zeka kuyruguna girer" do
    sign_out
    assert_enqueued_with(job: AiTriageJob) do
      post tickets_url, params: { ticket: { subject: "Yardım", requester_email: "x@example.com", birth_year: 2001 } }
    end
  end
end
