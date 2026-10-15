# Musterinin gizli linki icin tahmin edilemeyen anahtar.
# Mevcut taleplere (canlidaki demo talepleri dahil) de anahtar uretilir.
class AddAccessTokenToTickets < ActiveRecord::Migration[8.1]
  # Migrasyonda uygulama modelini kullanmiyoruz; model ileride degisse de migrasyon calisir.
  class MigrationTicket < ActiveRecord::Base
    self.table_name = "tickets"
  end

  def up
    add_column :tickets, :access_token, :string
    MigrationTicket.reset_column_information
    MigrationTicket.where(access_token: nil).find_each do |ticket|
      ticket.update_columns(access_token: SecureRandom.base58(24))
    end
    add_index :tickets, :access_token, unique: true
  end

  def down
    remove_index :tickets, :access_token
    remove_column :tickets, :access_token
  end
end
