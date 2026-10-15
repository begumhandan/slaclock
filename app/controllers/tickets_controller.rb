class TicketsController < ApplicationController
  # Musteri giris yapmadan talep acabilir; liste ve islemler temsilciye ozel.
  allow_unauthenticated_access only: %i[new create]
  before_action :set_ticket, only: %i[show transition assign_to_me]

  def index
    # Render ucretsiz planda uygulama uyudugu icin zamanlanmis is guvenilir degil;
    # zaman kurallari temsilci listeyi actiginda da uygulanir (bkz. AGENT.md).
    Ticket.apply_time_rules!
    @filter = params[:filter].presence_in(%w[awaiting sla_breached on_hold solved_today]) || "all"
    @tickets = Ticket.includes(:assignee).order(created_at: :desc)
    @tickets = case @filter
    when "awaiting" then @tickets.awaiting_first_response
    when "sla_breached" then @tickets.sla_breached
    when "on_hold" then @tickets.where(status: "on_hold")
    when "solved_today" then @tickets.where(solved_at: Time.current.all_day)
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
      redirect_to root_path, notice: "Talebiniz alindi. Talep numaraniz: ##{@ticket.id}"
    else
      render :new, status: :unprocessable_content
    end
  end

  def transition
    @ticket.transition_to!(params[:to])
    redirect_to @ticket, notice: "Durum guncellendi."
  rescue Ticket::InvalidTransition => e
    redirect_to @ticket, alert: e.message
  end

  def assign_to_me
    @ticket.assign_to!(Current.user)
    redirect_to @ticket, notice: "Talep size atandi."
  end

  private
    def set_ticket
      @ticket = Ticket.find(params[:id])
    end

    def ticket_params
      params.expect(ticket: %i[subject body requester_email priority])
    end
end
