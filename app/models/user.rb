class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :assigned_tickets, class_name: "Ticket", foreign_key: :assignee_id,
                              inverse_of: :assignee, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }
end
