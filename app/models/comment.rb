# Talep uzerindeki yanit. internal: true ise ic nottur (musteri gormez, SLA'yi durdurmaz).
class Comment < ApplicationRecord
  belongs_to :ticket
  belongs_to :author, class_name: "User", optional: true

  validates :body, presence: true

  scope :chronological, -> { order(:created_at) }
end
