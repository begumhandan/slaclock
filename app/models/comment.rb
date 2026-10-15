# Talep uzerindeki yanit. internal: true ise ic nottur (musteri gormez, SLA'yi durdurmaz).
class Comment < ApplicationRecord
  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true, length: { maximum: 10_000 }

  scope :chronological, -> { order(:created_at) }
  scope :visible_to_customer, -> { where(internal: false) }

  # Musteri yanitlarinin yazari yoktur (musteri giris yapmaz).
  def from_customer?
    author_id.nil?
  end
end
