# Resmi tatil. Bu gunlerde SLA sayaci islemez.
class Holiday < ApplicationRecord
  validates :date, presence: true, uniqueness: true
  validates :name, presence: true

  def self.name_on(date)
    find_by(date: date)&.name
  end
end
