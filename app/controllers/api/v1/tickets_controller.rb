# Agent-first API: musteri tarafindaki bir yapay zeka ajani talep acar, durumu izler, yanit yazar.
# Insan arayuzundeki (form, dugme) hicbir harekete ihtiyac yok; ayni is kurallari (Ticket modeli) calisir.
# Kimlik: Authorization: Bearer <AGENT_API_TOKEN> (Render ortam degiskeni). Belgeler: public/llms.txt
module Api
  module V1
    class TicketsController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_agent!
      before_action :set_ticket, only: %i[show reply]

      RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new
      rate_limit to: 20, within: 1.minute, store: RATE_LIMIT_STORE,
                 with: -> { render json: { error: "rate_limited" }, status: :too_many_requests }

      def create
        ticket = Ticket.new(ticket_params.merge(source: "api"))
        if ticket.save
          AiTriageJob.perform_later(ticket.id)
          render json: payload(ticket), status: :created
        else
          render json: { errors: ticket.errors.full_messages }, status: :unprocessable_content
        end
      end

      def show
        render json: payload(@ticket)
      end

      def reply
        @ticket.add_customer_reply!(body: params[:body].to_s)
        render json: payload(@ticket.reload), status: :created
      rescue ActiveRecord::RecordInvalid => e
        render json: { errors: e.record.errors.full_messages }, status: :unprocessable_content
      rescue Ticket::InvalidTransition => e
        render json: { errors: [ e.message ] }, status: :conflict
      end

      private
        def authenticate_agent!
          expected = ENV["AGENT_API_TOKEN"].to_s
          return render(json: { error: "api_disabled" }, status: :service_unavailable) if expected.blank?

          authenticate_or_request_with_http_token do |token, _options|
            ActiveSupport::SecurityUtils.secure_compare(token, expected)
          end
        end

        def set_ticket
          @ticket = Ticket.find_by(access_token: params[:token].to_s)
          render json: { error: "not_found" }, status: :not_found unless @ticket
        end

        def ticket_params
          params.permit(:requester_email, :requester_name, :subject, :body, :priority, :birth_year, :occupation, :city)
        end

        # Musterinin (ve onun ajaninin) gordugu gorunum: kendi verisi, ic notlar yok.
        def payload(ticket)
          {
            id: ticket.id,
            status: ticket.status,
            status_label: CustomerTicketsHelper::CUSTOMER_STATUS_LABELS[ticket.status],
            first_response_due_at: ticket.first_response_due_at&.iso8601,
            # Talebi kim ele aldi: "assistant" (yapay zeka yanitladi), "human" (insana devredildi), nil (bekleniyor)
            handled_by: { "answered" => "assistant", "handed_off" => "human", "disabled" => "human", "error" => "human" }[ticket.ai_status],
            customer_url: "#{request.base_url}/t/#{ticket.access_token}",
            api_url: "#{request.base_url}/api/v1/tickets/#{ticket.access_token}",
            messages: ticket.comments.visible_to_customer.chronological.map do |comment|
              { from: comment.from_customer? ? "customer" : (comment.from_ai? ? "assistant" : "support"),
                body: comment.from_customer? ? comment.body : ticket.unmask_for_customer(comment.body),
                at: comment.created_at.iso8601 }
            end
          }
        end
    end
  end
end
