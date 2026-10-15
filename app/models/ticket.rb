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

  # Ekranda gorunen durum adlari (hata mesajlari da bunlari kullanir).
  STATUS_LABELS = {
    "new" => "Yeni",
    "open" => "Açık",
    "pending" => "Müşteri bekleniyor",
    "on_hold" => "Beklemede (3. taraf)",
    "solved" => "Çözüldü",
    "closed" => "Kapandı"
  }.freeze

  # Zaman kurallari. Kod yeri: "Pending 3 gunde otomatik cozulsun" -> sadece bu sabitler.
  PENDING_AUTO_SOLVE_AFTER = 7.days # musteri bu kadar yanit vermezse talep cozulur
  SOLVED_AUTO_CLOSE_AFTER = 4.days # cozulen talep bu kadar sonra kapanir

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

  # Ilk temsilci yaniti bekleyen, sayaci isleyen talepler.
  scope :awaiting_first_response, -> { where(first_responded_at: nil, status: %w[new open pending]) }

  # Ilk yaniti verilmemis, SLA'si gecmis ve sayaci isleyen talepler.
  scope :sla_breached, -> { where(first_responded_at: nil, status: %w[new open pending], first_response_due_at: ...Time.current) }

  normalizes :requester_email, with: ->(email) { email.strip.downcase }

  validates :subject, presence: true, length: { maximum: 200 }
  validates :body, length: { maximum: 10_000 }
  validates :requester_email, presence: true, length: { maximum: 254 }, format: { with: URI::MailTo::EMAIL_REGEXP }

  def can_transition_to?(target)
    TRANSITIONS.fetch(status, []).include?(target.to_s)
  end

  def allowed_transitions
    TRANSITIONS.fetch(status, [])
  end

  def transition_to!(target)
    target = target.to_s
    unless can_transition_to?(target)
      target_label = STATUS_LABELS.fetch(target, "bilinmeyen bir durum")
      raise InvalidTransition, "#{STATUS_LABELS.fetch(status)} durumundan #{target_label} durumuna geçilemez."
    end

    transaction do
      # on_hold = ucuncu taraf bekleniyor: SLA sayaci durur, cikista devam eder.
      sla_pauses.create!(started_at: Time.current) if target == "on_hold"
      sla_pauses.ongoing.update_all(ended_at: Time.current) if status == "on_hold"

      # Ilk yanit verildiyse SLA sonuclanmistir; sonraki beklemeler son tarihi degistirmez.
      due_at = first_responded_at ? first_response_due_at : SlaClock.new(self).compute.due_at
      attributes = { status: target, status_changed_at: Time.current, first_response_due_at: due_at }
      attributes[:solved_at] = Time.current if target == "solved"
      attributes[:solved_at] = nil if status == "solved" && target == "open"
      update!(attributes)
    end
  end

  # Zamanla isleyen kurallar: pending'de bekleyen talepleri cozer, cozulmus talepleri kapatir.
  # TimeRulesJob ve talep listesi acilirken calisir (bkz. AGENT.md).
  def self.apply_time_rules!
    now = Time.current
    where(status: "pending", status_changed_at: ..(now - PENDING_AUTO_SOLVE_AFTER)).find_each do |ticket|
      ticket.transition_to!(:solved)
    end
    where(status: "solved", solved_at: ..(now - SOLVED_AUTO_CLOSE_AFTER)).find_each do |ticket|
      ticket.transition_to!(:closed)
    end
  end

  def auto_solve_at
    status_changed_at + PENDING_AUTO_SOLVE_AFTER if status == "pending" && status_changed_at
  end

  def auto_close_at
    solved_at + SOLVED_AUTO_CLOSE_AFTER if status == "solved" && solved_at
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

  def closed?
    status == "closed"
  end

  # Yeni bir talep bir temsilciye atandiginda otomatik olarak "open" olur.
  def assign_to!(user)
    raise InvalidTransition, "Kapalı talepte işlem yapılamaz" if closed?

    transaction do
      update!(assignee: user)
      transition_to!(:open) if status == "new"
    end
  end

  # Temsilci yaniti. Ilk herkese acik temsilci yaniti "ilk yanit" zamanini yazar
  # (ilk yanit SLA'si burada durur). Ic not ilk yanit sayilmaz.
  # Yeni bir talebe yanit veren temsilci, talep kimseye atanmamissa talebi ustlenir.
  def add_reply!(author:, body:, internal: false)
    raise InvalidTransition, "Kapalı talepte işlem yapılamaz" if closed?

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
