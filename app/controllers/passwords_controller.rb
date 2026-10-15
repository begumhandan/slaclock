class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :require_password_reset_enabled
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Çok fazla deneme yaptınız, birkaç dakika sonra tekrar deneyin." }

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Bu adrese kayıtlı bir hesap varsa şifre sıfırlama bağlantısı gönderildi."
  end

  def edit
  end

  def update
    if @user.update(params.permit(:password, :password_confirmation))
      @user.sessions.destroy_all
      redirect_to new_session_path, notice: "Şifreniz değiştirildi. Yeni şifrenizle giriş yapabilirsiniz."
    else
      redirect_to edit_password_path(params[:token]), alert: "Şifreler eşleşmedi."
    end
  end

  private
    # Canlida e-posta gonderilemedigi icin kapali (bkz. README Yapamadiklarim). Acmak: config.x.password_reset_enabled
    def require_password_reset_enabled
      return if Rails.configuration.x.password_reset_enabled

      redirect_to new_session_path, alert: "Şifre sıfırlama bu sürümde kapalı. Yeni şifre için yöneticiye başvurun."
    end

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Şifre sıfırlama bağlantısı geçersiz ya da süresi dolmuş."
    end
end
