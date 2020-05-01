class TambahColumnBaru < ActiveRecord::Migration
  def change
    add_column :transaction_history_details, :transaction_history_id, :integer
  end
end
