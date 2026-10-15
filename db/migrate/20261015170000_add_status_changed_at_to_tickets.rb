class AddStatusChangedAtToTickets < ActiveRecord::Migration[8.1]
  def change
    add_column :tickets, :status_changed_at, :datetime
  end
end
