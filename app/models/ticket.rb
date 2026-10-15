class Ticket < ApplicationRecord
  class InvalidTransition < StandardError; end

  # Durum akisi: hangi durumdan hangisine gecilebilir?
  # Gecis kurali degisecekse SADECE bu tablo degisir (bkz. AGENT.md, kural haritasi).
  TRANSITIONS = {
    "new" => %w[open],
    "open" => %w[pending on_hold solved],
    "pending" => %w[open solved],
    "on_hold" => %w[open],
    "solved" => %w[open closed],
    "closed" => []
  }.freeze

  # instance_methods: false -> solved! gibi korumasiz bang metotlari URETILMEZ.
  # Durum yalnizca transition_to! ile degisir. (Rails enum'u bir durum makinesi degildir.)
  enum :status, { new: 0, open: 1, pending: 2, on_hold: 3, solved: 4, closed: 5 },
       instance_methods: false, scopes: false, validate: true
  enum :priority, { low: 0, normal: 1, high: 2, urgent: 3 }, validate: true

  belongs_to :assignee, class_name: "User", optional: true

  validates :subject, presence: true
  validates :requester_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def can_transition_to?(target)
    TRANSITIONS.fetch(status, []).include?(target.to_s)
  end

  def allowed_transitions
    TRANSITIONS.fetch(status, [])
  end

  def transition_to!(target)
    target = target.to_s
    unless can_transition_to?(target)
      raise InvalidTransition, "#{status} durumundan #{target} durumuna gecilemez"
    end

    attributes = { status: target }
    attributes[:solved_at] = Time.current if target == "solved"
    attributes[:solved_at] = nil if status == "solved" && target == "open"
    update!(attributes)
  end

  # Yeni bir talep bir temsilciye atandiginda otomatik olarak "open" olur.
  def assign_to!(user)
    transaction do
      update!(assignee: user)
      transition_to!(:open) if status == "new"
    end
  end
end
