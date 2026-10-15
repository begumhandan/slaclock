class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "SLA Clock <onboarding@resend.dev>")
  layout "mailer"
end
