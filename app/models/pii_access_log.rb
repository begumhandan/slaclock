# Gercek kisisel veriye kim, ne zaman, hangi gerekceyle bakti? (Gizlilik maskesinin denetim kaydi)
class PiiAccessLog < ApplicationRecord
  belongs_to :ticket
  belongs_to :user

  validates :reason, presence: true, length: { minimum: 5, maximum: 300 }

  scope :recent_first, -> { order(created_at: :desc) }
end
