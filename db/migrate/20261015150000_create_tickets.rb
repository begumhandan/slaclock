class CreateTickets < ActiveRecord::Migration[8.1]
  def change
    create_table :tickets do |t|
      t.string :subject, null: false
      t.text :body
      t.string :requester_email, null: false
      t.integer :priority, null: false, default: 1
      t.integer :status, null: false, default: 0
      t.references :assignee, foreign_key: { to_table: :users }
      t.datetime :first_response_due_at
      t.datetime :first_responded_at
      t.datetime :solved_at

      t.timestamps
    end
    add_index :tickets, :status
  end
end
