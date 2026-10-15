class CommentsController < ApplicationController
  def create
    @ticket = Ticket.find(params[:ticket_id])
    @ticket.add_reply!(
      author: Current.user,
      body: comment_params[:body],
      internal: comment_params[:internal] == "1"
    )
    redirect_to @ticket, notice: "Yanıt eklendi."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @ticket, alert: e.record.errors.full_messages.to_sentence
  rescue Ticket::InvalidTransition => e
    redirect_to @ticket, alert: e.message
  end

  private
    def comment_params
      params.expect(comment: %i[body internal])
    end
end
