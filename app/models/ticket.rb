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
  has_many :comments, dependent: :destroy
  has_many :sla_pauses, dependent: :destroy

  # Turetilmis alan: ilk yanit son tarihi (SlaClock hesaplar). AGENT.md: callback yalnizca turetilmis alan icin.
  before_create { self.first_response_due_at = SlaClock.new(self).compute.due_at }

  # Ilk yaniti verilmemis, SLA'si gecmis ve sayaci isleyen talepler.
  scope :sla_breached, -> { where(first_responded_at: nil, status: %w[new open pending], first_response_due_at: ...Time.current) }

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

    transaction do
      # on_hold = ucuncu taraf bekleniyor: SLA sayaci durur, cikista devam eder.
      sla_pauses.create!(started_at: Time.current) if target == "on_hold"
      sla_pauses.ongoing.update_all(ended_at: Time.current) if status == "on_hold"

      attributes = { status: target, first_response_due_at: SlaClock.new(self).compute.due_at }
      attributes[:solved_at] = Time.current if target == "solved"
      attributes[:solved_at] = nil if status == "solved" && target == "open"
      update!(attributes)
    end
  end

  # :running, :paused, :met, :breached
  def sla_state(now = Time.current)
    if first_responded_at
      first_response_due_at && first_responded_at > first_response_due_at ? :breached : :met
    elsif status == "on_hold"
      :paused
    elsif first_response_due_at.nil?
      :running
    elsif status.in?(%w[solved closed])
      (solved_at || now) > first_response_due_at ? :breached : :met
    else
      now > first_response_due_at ? :breached : :running
    end
  end

  # Yeni bir talep bir temsilciye atandiginda otomatik olarak "open" olur.
  def assign_to!(user)
    transaction do
      update!(assignee: user)
      transition_to!(:open) if status == "new"
    end
  end

  # Temsilci yaniti. Ilk herkese acik temsilci yaniti "ilk yanit" zamanini yazar
  # (ilk yanit SLA'si burada durur). Ic not ilk yanit sayilmaz.
  # Yeni bir talebe yanit veren temsilci, talep kimseye atanmamissa talebi ustlenir.
  def add_reply!(author:, body:, internal: false)
    transaction do
      comment = comments.create!(author: author, body: body, internal: internal)

      unless internal
        update!(assignee: author) if assignee.nil?
        transition_to!(:open) if status == "new"
        update!(first_responded_at: comment.created_at) if first_responded_at.nil?
      end

      comment
    end
  end
end
