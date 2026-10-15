class PasswordsMailer < ApplicationMailer
  def reset(user)
    @user = user
    mail subject: "SLA Clock: şifre sıfırlama", to: user.email_address
  end
end
