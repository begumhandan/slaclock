class TicketsController < ApplicationController
  # Musteri giris yapmadan talep acabilir; liste ve islemler temsilciye ozel.
  allow_unauthenticated_access only: %i[new create]
  before_action :set_ticket, only: %i[show transition assign_to_me reveal]

  # Herkese acik form: ayni adresten dakikada en fazla 5 talep (spam korumasi).
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
  rate_limit to: 5, within: 1.minute, only: :create, store: RATE_LIMIT_STORE,
             with: -> { redirect_to new_ticket_path, alert: "Çok fazla talep gönderdiniz. Bir dakika sonra tekrar deneyin." }

  def index
    # Render ucretsiz planda uygulama uyudugu icin zamanlanmis is guvenilir degil;
    # zaman kurallari temsilci listeyi actiginda da uygulanir (bkz. AGENT.md).
    Ticket.apply_time_rules!
    @filter = params[:filter].presence_in(%w[awaiting sla_breached on_hold solved_today handed_off]) || "all"
    @tickets = Ticket.includes(:assignee).order(created_at: :desc)
    @tickets = case @filter
    when "awaiting" then @tickets.awaiting_first_response
    when "sla_breached" then @tickets.sla_breached
    when "on_hold" then @tickets.where(status: "on_hold")
    when "solved_today" then @tickets.where(solved_at: Time.current.all_day)
    when "handed_off" then @tickets.where(ai_status: "handed_off").where.not(status: %w[solved closed])
    else @tickets
    end
  end

  def show
  end

  def new
    @ticket = Ticket.new
  end

  def create
    @ticket = Ticket.new(ticket_params)

    if @ticket.save
      AiTriageJob.perform_later(@ticket.id)
      redirect_to customer_ticket_path(@ticket.access_token),
                  notice: "Talebiniz alındı (##{@ticket.id}). Bu sayfanın linkini saklayın: yanıtlarımızı burada göreceksiniz."
    else
      render :new, status: :unprocessable_content
    end
  end

  # Gercek kisisel veriyi gosterir: gerekce zorunlu, her erisim kayda gecer (PiiAccessLog).
  def reveal
    log = @ticket.pii_access_logs.new(user: Current.user, reason: params[:reason].to_s.strip)
    if log.save
      @revealed = true
      render :show
    else
      redirect_to @ticket, alert: "Gerçek veriyi görmek için en az 5 karakterlik bir gerekçe yazın."
    end
  end

  def transition
    @ticket.transition_to!(params[:to])
    redirect_to @ticket, notice: "Durum güncellendi."
  rescue Ticket::InvalidTransition => e
    redirect_to @ticket, alert: e.message
  end

  def assign_to_me
    @ticket.assign_to!(Current.user)
    redirect_to @ticket, notice: "Talep size atandı."
  rescue Ticket::InvalidTransition => e
    redirect_to @ticket, alert: e.message
  end

  private
    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def ticket_params
      params.expect(ticket: %i[subject body requester_email priority requester_name birth_year occupation city])
    end
end
