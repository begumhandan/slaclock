# Talep uzerindeki yanit. internal: true ise ic nottur (musteri gormez, SLA'yi durdurmaz).
class Comment < ApplicationRecord
  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: 10_000 }
  validates :intent, inclusion: { in: %w[resolved new_info other] }, allow_nil: true

  # Turetilmis alan: musteri yanitinin maskeli hali (temsilci ve LLM bunu gorur).
  before_create { self.masked_body = ticket.privacy_mask.apply(body) if from_customer? }

  scope :chronological, -> { order(:created_at) }
  scope :visible_to_customer, -> { where(internal: false) }

  # Musteri yanitlarinin yazari yoktur (musteri giris yapmaz). Asistan yanitlari ai_generated isaretlidir.
  def from_customer?
    author_id.nil? && !ai_generated
  end

  def from_ai?
    ai_generated
  end

  # Temsilci ekraninda gosterilecek metin: musteri yazdiysa maskeli hali.
  def agent_body
    from_customer? ? (masked_body || ticket.privacy_mask.apply(body)) : body
  end
end
