class CreateSlaPauses < ActiveRecord::Migration[8.1]
  def change
    create_table :sla_pauses do |t|
      t.references :ticket, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :ended_at

      t.timestamps
    end
  end
end
