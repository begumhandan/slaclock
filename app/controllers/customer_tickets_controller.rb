# Musterinin talep sayfasi. Musteri giris yapmaz; sayfaya yalnizca talep acilinca verilen
# tahmin edilemeyen linkle (/t/:token) ulasir. E-postadaki "talebinizi goruntuleyin" linkinin yerini tutar.
class CustomerTicketsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_ticket
  after_action :keep_link_private

  # Ayni adresten dakikada en fazla 10 yanit (spam korumasi).
  REPLY_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 10, within: 1.minute, only: :reply, store: REPLY_LIMIT_STORE,
             with: -> { redirect_to customer_ticket_path(params[:token]), alert: "Çok fazla yanıt gönderdiniz. Bir dakika sonra tekrar deneyin." }

  def show
    @comments = @ticket.comments.visible_to_customer.chronological
  end

  def reply
    @ticket.add_customer_reply!(body: params.expect(reply: [ :body ])[:body])
    redirect_to customer_ticket_path(@ticket.access_token), notice: "Yanıtınız ekibe iletildi."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to customer_ticket_path(@ticket.access_token), alert: e.record.errors.full_messages.to_sentence
  rescue Ticket::InvalidTransition => e
    redirect_to customer_ticket_path(@ticket.access_token), alert: e.message
  end

  private
    # Yanlis ya da eksik anahtar -> 404 (talebin var olup olmadigi bile belli olmaz).
    def set_ticket
      @ticket = Ticket.find_by!(access_token: params[:token].to_s)
    end

    # Link baska sitelere "Referer" ile sizmasin, arama motorlari indekslemesin.
    # "no-referrer" KULLANILMAZ: tarayici o zaman form gonderirken "Origin: null" yollar ve
    # Rails'in CSRF origin kontrolu musteri yanitini 422 ile reddeder. "same-origin" linki
    # yalnizca kendi sitemize gonderir, disari sizdirmaz.
    def keep_link_private
      response.headers["Referrer-Policy"] = "same-origin"
      response.headers["X-Robots-Tag"] = "noindex, nofollow"
    end
end
