require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  test "ana sayfa giris yapmadan acilir" do
    get root_url
    assert_response :success
  end
end
