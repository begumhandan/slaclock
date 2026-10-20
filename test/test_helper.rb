ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"
require_relative "test_helpers/fake_llm"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    # SQLite + thread paralelligi "database is locked" veriyor; testler tek is parcacigiyla yeterince hizli (~10 sn).
    parallelize(workers: 1)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Talep formu istek siniri testler arasinda birikmesin.
    setup do
      TicketsController::RATE_LIMIT_STORE.clear
      CustomerTicketsController::REPLY_LIMIT_STORE.clear
      Api::V1::TicketsController::RATE_LIMIT_STORE.clear
      # Testler gercek LLM'i asla cagirmaz; varsayilan olarak yapay zeka kapali.
      LlmClient.adapter = FakeLlm.new(nil, enabled: false)
    end

    # Add more helper methods to be used by all tests here...
  end
end
