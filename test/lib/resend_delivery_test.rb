require "test_helper"

class ResendDeliveryTest < ActiveSupport::TestCase
  test "sifre sifirlama e-postasi Resend API bicimine donusur" do
    mail = PasswordsMailer.reset(users(:one))
    payload = ResendDelivery.new(api_key: "test").payload(mail)

    assert_equal [ users(:one).email_address ], payload[:to]
    assert_equal "SLA Clock: şifre sıfırlama", payload[:subject]
    assert_includes payload[:html], "/passwords/"
    assert_includes payload[:text], "dakika geçerlidir"
    assert_match "SLA Clock", payload[:from]
  end
end
