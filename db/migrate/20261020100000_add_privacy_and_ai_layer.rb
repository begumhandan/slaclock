# Gizlilik maskesi (sentetik profil + maskeli metin) ve LLM/ajan katmani icin alanlar.
# Mevcut taleplere (canlidaki demo talepleri dahil) maske ve persona geriye donuk uygulanir.
class AddPrivacyAndAiLayer < ActiveRecord::Migration[8.1]
  class MigrationTicket < ActiveRecord::Base
    self.table_name = "tickets"
  end

  class MigrationComment < ActiveRecord::Base
    self.table_name = "comments"
  end

  def up
    change_table :tickets, bulk: true do |t|
      t.string :requester_name
      t.integer :birth_year
      t.string :occupation
      t.string :city
      t.string :persona_name
      t.string :persona_summary
      t.string :masked_subject
      t.text :masked_body
      t.string :source, null: false, default: "web"
      t.string :ai_status
      t.string :ai_category
      t.string :ai_priority
      t.text :ai_summary
      t.text :ai_reason
    end

    change_table :comments, bulk: true do |t|
      t.text :masked_body
      t.boolean :ai_generated, null: false, default: false
      t.string :intent
    end

    create_table :pii_access_logs do |t|
      t.references :ticket, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :reason, null: false
      t.datetime :created_at, null: false
    end

    MigrationTicket.reset_column_information
    MigrationComment.reset_column_information
    MigrationTicket.find_each do |ticket|
      persona = SyntheticPersona.for(email: ticket.requester_email)
      mask = PrivacyMask.new(persona_name: persona.name)
      ticket.update_columns(persona_name: persona.name, persona_summary: persona.summary,
                            masked_subject: mask.apply(ticket.subject), masked_body: mask.apply(ticket.body))
      MigrationComment.where(ticket_id: ticket.id, author_id: nil).find_each do |comment|
        comment.update_columns(masked_body: mask.apply(comment.body))
      end
    end
  end

  def down
    drop_table :pii_access_logs
    remove_columns :comments, :masked_body, :ai_generated, :intent
    remove_columns :tickets, :requester_name, :birth_year, :occupation, :city, :persona_name, :persona_summary,
                   :masked_subject, :masked_body, :source, :ai_status, :ai_category, :ai_priority, :ai_summary, :ai_reason
  end
end
