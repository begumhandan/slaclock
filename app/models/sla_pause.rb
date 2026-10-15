# Talep "on_hold" (ucuncu taraf bekleniyor) durumundayken SLA sayacinin durdugu aralik.
class SlaPause < ApplicationRecord
  belongs_to :ticket

  validates :started_at, presence: true

  scope :chronological, -> { order(:started_at) }
  scope :ongoing, -> { where(ended_at: nil) }
end
